# ColorMatcher


## Description

This command line tool finds the closest color between a candidate color and a pallete of colors.  
The main purpose of this project is to provide an easy solution to readjust colors with theme guidelines.

## Build
```
$ swift build --configuration release
$ cp -f .build/release/banner /usr/local/bin/banner
```

## Usage 

`$ color-matcher match CANDIDATE SPEC [--results-folder FOLDER] [--replaceXibColors]`
  
### Cadidate | Spec colors
  
  
**XIB**

Uses the colors in the `xib` file as candidate or spec colors.

*Example:*  
`$ color-matcher match ./myView1.xib ./myView2.xib [--results-folder FOLDER] [--replaceXibColors]`  

**Hexadecimal**

Uses the hexadecimal value as candidate or spec color.

*Example:*  
`$ color-matcher match 0xFFFFFF 0xFFFFF [--results-folder FOLDER] [--replaceXibColors]`  

**JSON**

Uses the colors in the `json` file as candidate or spec colors. The file should be structures as an array of `ColorSpec` elements.

*Example:*  
`$ color-matcher match ./candidates.json ./specs.json [--results-folder FOLDER] [--replaceXibColors]`

**XCAssets**

Uses the colors in the `xcassets` file as candidate or spec colors. 

*Example:*
`$ color-matcher match ./candidates.xcassets ./specs.xcassets [--results-folder FOLDER] [--replaceXibColors]`

### Options

** --results-folder**

Stores two images per candidate color with the original and best fit colors.  

**--replaceXibColors**

In case the candidate input is a `xib` file, the colors are replaced with the most suitable colors in the specs.
