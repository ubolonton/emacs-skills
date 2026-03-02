---
name: gnuplot
description: 'This skill should be used when the user invokes "/gnuplot" to plot data from the current context using gnuplot and output the resulting image path.'
tools: Bash
disable-model-invocation: true
---

# Plot data with gnuplot

Plot data from the most recent interaction context using gnuplot. Generate a PNG image with a transparent background and output it as a markdown image so it renders inline.

## How to plot

1. Extract or derive plottable data from the current context.
2. Write a gnuplot script to a temporary file.
3. Run gnuplot on the script.
4. Output the result as a markdown image on its own line:
   ```
   ![description](/tmp/agent-plot-XXXX.png)
   ```

```sh
gnuplot /tmp/agent-plot-XXXX.gp
```

## Gnuplot script template

```gnuplot
set terminal pngcairo transparent enhanced size 800,500
set output "/tmp/agent-plot-XXXX.png"

# ... plot commands using the data ...
```

## Rules

- Always use `pngcairo transparent` terminal for transparent background.
- Use a unique filename under `/tmp/` (e.g., `/tmp/agent-plot-<timestamp>.png`).
- Use inline data (`$DATA << EOD ... EOD`) when practical. For large datasets, write a separate data file.
- After gnuplot runs successfully, output a markdown image (`![description](path)`) on its own line.
- Choose an appropriate plot type for the data (lines, bars, histogram, scatter, etc.).
- Include a title, axis labels, and a legend when they add clarity.
- Use `enhanced` text mode for subscripts/superscripts when needed.
- If no plottable data exists in the recent context, inform the user.
