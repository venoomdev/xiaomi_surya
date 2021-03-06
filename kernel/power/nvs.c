/*
 * linux/kernel/power/hibernate_nvs.c - Routines for handling NVS memory
 *
 * Copyright (C) 2008,2009 Rafael J. Wysocki <rjw@sisk.pl>, Novell Inc.
 *
 * This file is released under the GPLv2.
 */

#include <linux/io.h>
#include <linux/kernel.h>
#include <linux/list.h>
#include <linux/mm.h>
#include <linux/slab.h>
#include <linux/suspend.h>

/*
 * Platforms, like ACPI, may want us to save some memory used by them during
 * suspend and to restore the contents of this memory during the subsequent
 * resume.  The code below implements a mechanism allowing us to do that.
 */

struct nvs_page {
	unsigned long phys_start;
	unsigned int size;
	void *kaddr;
	void *data;
	struct list_head node;
};

static LIST_HEAD(nvs_list);

/**
 *	suspend_nvs_register - register platform NVS memory region to save
 *	@start - physical address of the region
 *	@size - size of the region
 *
 *	The NVS region need not be page-aligned (both ends) and we arrange
 *	things so that the data from page-aligned addresses in this region will
 *	be copied into separate RAM pages.
 */
int suspend_nvs_register(unsigned long start, unsigned long size)
{
	struct nvs_page *entry, *next;

	while (size > 0) {
		unsigned int nr_bytes;

		entry = kzalloc(sizeof(struct nvs_page), GFP_KERNEL);
		if (!entry)
			goto Error;

		list_add_tail(&entry->node, &nvs_list);
		entry->phys_start = start;
		nr_bytes = PAGE_SIZE - (start & ~PAGE_MASK);
		entry->size = (size < nr_bytes) ? size : nr_bytes;

		start += entry->size;
		size -= entry->size;
	}
	return 0;

 Error:
	list_for_each_entry_safe(entry, next, &nvs_list, node) {
		list_del(&entry->node);
		kfree(entry);
	}
	return -ENOMEM;
}

/**
 *	suspend_nvs_free - free data pages allocated for saving NVS regions
 */
void suspend_nvs_free(void)
{
	struct nvs_page *entry;

	list_for_each_entry(entry, &nvs_list, node)
		if (entry->data) {
			free_page((unsigned long)entry->data);
			entry->data = NULL;
			if (entry->kaddr) {
				iounmap(entry->kaddr);
				entry->kaddr = NULL;
			}
		}
}

/**
 *	suspend_nvs_alloc - allocate memory necessary for saving NVS regions
 */
int suspend_nvs_alloc(void)
{
	struct nvs_page *entry;

	list_for_each_entry(entry, &nvs_list, node) {
		entry->data = (void *)__get_free_page(GFP_KERNEL);
		if (!entry->data) {
			suspend_nvs_free();
			return -ENOMEM;
		}
	}
	return 0;
}

/**
 *	suspend_nvs_save - save NVS memory regions
 */
void suspend_nvs_save(void)
{
	struct nvs_page *entry;

	printk(KERN_INFO "PM: Saving platform NVS memory\n");

	list_for_each_entry(entry, &nvs_list, node)
		if (entry->data) {
			entry->kaddr = ioremap(entry->phys_start, entry->size);
			memcpy(entry->data, entry->kaddr, entry->size);
		}
}

/**
 *	suspend_nvs_restore - restore NVS memory regions
 *
 *	This function is going to be called with interrupts disabled, so it
 *	cannot iounmap the virtual addresses used to access the NVS region.
 */
void suspend_nvs_restore(void)
{
	struct nvs_page *entry;

	printk(KERN_INFO "PM: Restoring platform NVS memory\n");

	list_for_each_entry(entry, &nvs_list, node)
		if (entry->data)
			memcpy(entry->kaddr, entry->data, entry->size);
}

