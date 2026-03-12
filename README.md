# vid2avif

*Video to AVIF converter*

![sample avif file](sample.avif)

(Very early version of...)
A batch script for converting video files to AVIF using FFmpeg.
Supports scaling, trimming and cropping and preview using 'ffplay'.

By *Pathduck*

## Installation

* Clone the repo.

* Install [FFmpeg](https://www.ffmpeg.org/).

* For Windows make sure that the path to `ffmpeg.exe` is
  [configured in your system environment variables control panel](https://www.wikihow.com/Install-FFmpeg-on-Windows).

## Usage
```
vid2avif [input_file] [arguments]
```

## Arguments
```
 -o  Output file. Default is the same as input file, sans extension
 -r  Scale or size. Width of the animation in pixels
 -f  Framerate in frames per seconds (default 15)
 -s  Start time of the animation (HH:MM:SS.MS)
 -e  End time of the animation (HH:MM:SS.MS)
 -x  Crop the input video (out_w:out_h:x:y)
 -y  Preview animation using 'FFplay' (part of FFmpeg)
     (Useful for testing cropping, but will not use exact start/end time)
 -p  Opens the resulting animation in the default image viewer
 -v  Set FFmpeg log level (default: error)
```

## Notes

* Cropping works on the input video before scaling is performed, and passes the parameters
  directly to the [FFmpeg crop filter](https://ffmpeg.org/ffmpeg-filters.html#crop).

* Preview uses FFplay and the script will check for its existence on the PATH.
  FFplay is usually installed along with FFmpeg. The preview is not time-accurate
  and is mostly useful for testing cropping.

* The script will attempt to check for valid inputs, but will fall back to
  FFmpeg's error messages.

* The script uses ffmpeg, you can download that here: [FFmpeg](https://www.ffmpeg.org/)

* The script is based on: [Pathduck/vid2ani](https://github.com/Pathduck/vid2ani)
