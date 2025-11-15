#ifndef LIQ_HIST_H
#define LIQ_HIST_H

#include <stdbool.h> // For bool
#include <stddef.h>  // For size_t
#include "imagequant.h" // For liq_color

typedef struct liq_hist_entry {
    liq_color color;
    float r, g, b, a; // For floating point calculations of the color
    int count;
    struct liq_hist_entry *next;
} liq_hist_entry;

typedef struct liq_histogram {
    liq_hist_entry *all_entries_list; // linked list of all entries (for easy iteration)
    liq_hist_entry *entries[257]; // hash table for quick lookup (optimized for 256 colors + transparency)
    int count; // number of unique colors
    int max_colors; // maximum colors allowed in the histogram (for median cut)
    int min_val_alpha; // minimum alpha value observed
    int max_val_alpha; // maximum alpha value observed
    bool has_full_alpha; // whether any pixel has alpha 255
    bool has_zero_alpha; // whether any pixel has alpha 0
} liq_histogram;

liq_histogram *liq_hist_create(int max_colors);
void liq_hist_destroy(liq_histogram *hist);
void liq_hist_add_color(liq_histogram *hist, liq_color color);
long liq_hist_get_count(const liq_histogram *hist);
void liq_hist_get_colors(const liq_histogram *hist, liq_color *colors_out, size_t *count_out);

#endif // LIQ_HIST_H




#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#include "imagequant.h"
#include "types.h"

#include "hist.h"    	
#include "nearest.h" 
#include "vle.h"     