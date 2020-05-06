# ColorMatcher


## Description

This command line tool gives you the most approximate color from an input against a color palette.
The main purpose of this project was to provide an easy tool to follow or readjust colors with project theme guidelines.

## Usage 

In order to use this tool, you need to provide a `spec.json` and either an hex value (`--hex`) or a input source  (`--input-colors-path`) with the same format as the spec.
  
  
`swift run color-matcher distance ./Examples/spec.json --hex 0x111000 --input-colors-path Examples/input.json --results-folder ./Results`
