# quarto-schedule

A Quarto extension that renders an interactive, tabbed event schedule (one
tab per day) from a YAML data file. No Python or R required at render time
&mdash; it's a pure Lua shortcode.

Modeled on the schedule at [book-template.hackweek.io](https://book-template.hackweek.io/),
which is hand-built HTML/JS; this reimplements it as a reusable Quarto
component driven by Quarto's native `panel-tabset`.

## Installing

From the project you want to use it in:

```bash
quarto add uwhackweek/quarto-schedule
```

(or, until this is published: `quarto add /path/to/quarto-schedule`, or copy
the `_extensions/schedule` directory into your project's `_extensions/`.)

## Usage

Requires a Bootstrap-based HTML format (the default for Quarto websites and
`format: html`).

1. Write a schedule YAML file, e.g. `data/schedule.yml`:

   ```yaml
   timezone: "UTC+1 (Central European Time)"
   days:
     - title: "Day 1"
       date: "Monday, 9 March"
       sessions:
         - time: "9:00 - 9:30"
           title: "Welcome & Introductions"
           leads: ["Jane Doe"]
           description: "Kickoff, logistics, and introductions."
         - time: "10:00 - 10:30"
           title: "BREAK"
           type: "break"
           leads: []
           description: ""
         - time: "10:30 - 17:00"
           title: "Open Project Work"
           type: "work"
           leads: []
           description: ""
   ```

2. Drop the shortcode into any `.qmd`:

   ````
   {{< schedule file="data/schedule.yml" >}}
   ````

That's it — the shortcode reads the file at render time and builds the
tabset, no code cell needed.

### Schedule file format

- `timezone` &mdash; shown above the tabset.
- `days` &mdash; list of tabs, each with `title`, `date`, and `sessions`.
- Each session has `time`, `title`, `leads` (list of names, may be empty),
  and `description` (may be empty).
- `type` (optional) sets the row's color class (`sched-<type>`), e.g.
  `type: "break"` or `type: "lunch"`. Sessions without a `type` get the
  default styling. Add more types by adding a matching `.sched-<type>` rule
  to `_extensions/schedule/schedule.css`.

## Development

`demo.qmd` + `example/schedule.yml` at the repo root are a live example.
After changing the filter, re-render with:

```bash
quarto render demo.qmd
```
