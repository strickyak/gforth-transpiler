\  Multi-tasking Doppler RDF bearings processing using an FIR filter
\  First concurrent task launched in ARM core 1
\  TaskA

\              Andrew Korsak  KR6DD   20240410

\ Major contributions were:
\ (a) a Gforth to C++ transpiler and Makefile from Henry W6REK that
\     speeds up my Gforth program by a factor around 5 to 7
\ (b) a PWM/DMA based antenna switcher procedure from Christopher AI6KG
\     that provides extremely stable antenna switching and synch pulses

\ Credits are also due to Shri KA6Q, Mike NE6RD, and various other hams
\ who coached me as a Linux usage beginner.

\ This program is the first task of four concurrent tasks for deriving
\ bearings from receiver audio with the antenna connected to a four
\ dipole Doppler array whose dipole elements are switched on one at a
\ time by 4 GPIO pin outputs connected through RF chokes to one diode on
\ a center switching PC board, then through a short coax to a second
\ diode at a dipole feed point, thereby leaving the other 3 dipoles and
\ their coaxes (ideally) floating in space and isolated from the
\ junction point of 4 coupling capacitors connected to a coax going to
\ the receiver.

\ My FIR filter implementation in Gforth uses 64-bit IEEE floating point
\ coefficients and associated Gforth floating point functions for most
\ of the signal processing.  The four tasks run in separate ARM processor
\ cores in order to allow increasing the FIR filter length and to
\ provide a deeper attenuation outside a narrow pass band centered at the
\ Doppler tone frequency resuting from "psudo-Doppler antenna rotation".
\ FIR filter computations can be split among 4 concurrent tasks, each one
\ working on a quarter of the 16bit stereo buffer. The four tasks are
\ described in comments of
\ send-S16stereo-buf-remainder-to-TasksB,C,D

\ 20231129 Changed data passed by tasks A, B, and C to TaskD from averaged
\  Doppler tone phase angle and magnitude to 2D angle vector format.

\ 20230819 Began a version of four tasks that pass S16 stereo
\ buffer 2nd, 3rd and 4th quarters as text files to TaskB, TaskC and
\ TaskD for multitasking performance evaluation prior to completing a
\ set of four concurrent tasks running in four separate ARM processor
\ cores with S16 data passed by Linux piping.

\ TaskA first reads S16 stereo sound card data (or previosly recorded file
\ data), then writes out the three buffer quarters data to named files,
\ each preceeded by FIR filter history required back of each buffer
\ quarter.
\ Then it begins FIR filtering and computing an average bearing vector
\ angle and magnitude and a max Doppler tone peak value, and tacks that
\ onto the tail end of a fourth named file designated for TaskD.

\ TaskB first reads into a buffer the second quarter of the S16 buffer
\ read in by TaskA and passed to TaskB, then proceeds to FIR filter and
\ compute averaged bearing vector angle and magnitude and peak tone value,
\ then it taks that onto the tail end of the fourth named file designated
\ for TaskD.

\ TaskC first reads into a buffer the third quarter of the S16 buffer
\ read in by TaskA and passed to TaskC, then proceeds to FIR filter and
\ compute averaged bearing vector angle and magnitude and peak tone value,
\ then it taks that onto the tail end of the fourth named file designated
\ for TaskD.

\ TaskD first reads into a buffer the fourth quarter of the S16 buffer
\ read in by TaskA and passed to TaskD, then it proceeds to FIR filter and
\ compute averaged bearing vector angle and magnitude and peak tone value,
\ then it reads the averaged vector and tone peak data from the fourth
\ named file designated for TaskD, computes the averaged bearing vector
\ angle value, combines the four bearing vector averages, and finally it
\ sends a report via stdout in the format required for the rdf.kn5r.net
\ bearings reporting website.

\ 20240326 Fixed count gap to bearing angle conversion error

\ 20231228 Prepared for testing four concurrent tasks launched by
\ command line.

\ 20230706 Began splitting signal processing among 2-4 concurrent tasks
\  in separate ARM processor cores piping S16 stereo buffer remaining
\  quarters forward to the next of 2 to 4 tasks.

\ 20230704 Debug tools helped to find when and how this program prior to
\  June 3 was writing over its source code when running interactive
\  gforth but not when running optimized by the GFTP.
\ 20230702 Added debugging tools to trap overwriting source code by
\  stepping beyond array limits.
\ 20230619 Continued from Task2Jun18webB changes.
\ 20230604 Continued from the 20230321 version, adding modifications up to
\  Apr 13 for the option to read S16 stereo data from a previously
\ recorded file.

\ 20230319 Modified spike counts interpolation method to use rectangular
\  window intersection instead of quadratic polynomial interpolation.

\ 20230310 Renamed smooth-the-spikes as interpolate-spike-counts and began
\  adapting the quadratic polynomial interpolation of a floating point
\  spike leading edge "count" when using independent RIGHT stereo channel
\  data from the CM6202 sound card.

\ 20230309 Corrected using 30 as the number of expected sound card
\  cycles per antenna rotation to approximately 29.952, slightly under 30.
\  This is verified when running this task in debug mode and displaying
\  the actual number of FIR filtered Doppler tone neg to pos zero
\  crossings. Given 624 us per antenna rotation instead of the previous
\  625 us value approximately set by a SW timing loop in a "Task1"
\  running in a separate ARM core from this "Task2", measured Doppler
\  tone frequency is now slightly above 1.6kHz.
\  Since the use of SW loops in a separate ARM CPU core was replaced by
\  AI6KG's DMA and PWM, the expected time between antenna switchings from
\  one of 4 antennas to the next one in circular order is 156 usec,
\  resulting in full antenna rotations every 624 usec, to within
\  precision of the RPi3B PWM clock. This leads to an antenna rotation
\  rate of 1602.564 rps and a Doppler tone frequency approximately varying
\  between 1.602 and 1.603 kHz (as verified by viewing the spectrum of FIR
\  filtered Doppler tone recordings via audacity during SW development and
\  debugging).

\ 20230308 sped up setting batch section pointers by splitting
\ init-batch-buffer-section-ptrs into two parts, one at the start of a
\ batch and an update at the start of each batch section for the original,
\ spike, and filtered buffer pointers

\ 20230216 restored smooth-the-spikes to store a quadratic polynimial fit
\  to first and second halves of a spike

\ 20230214 adapted open-sound-card input to deploy a CM6202 stereo unit
\ and deleted use of smooth-the-spikes

\ 20230211 temporarily debugging gpavs with gforth-fast and 800 of 2400
\  total smaples per batch section before testing at full speed with the
\  GFTP

\ 20230210 restored recording signal, smoothed, and FIR filtered files for
\  investigating performance

\ 20230205 fixed problem with open-sound-card-input causing crashes after
\  long Task2 runs

\ 20230201 fixed bugs in gpavs causing occasional crashes

\ 20230130 reverted to live sound card reading for comparing preformance
\  with latest Jan 30 version

\ 20230109 completed ensuring that after each spike the earliest zero+
\  crossing is used having its interpolated count at or after the spike's

\ 20221229 split coeffs-fixed-point-array into 2 parts,
\  coeffs-fixed-point-mantissa-array, coeffs-fixed-point-exponent-array,
\  to fix a segmentation error suddenly happening with the transpiled
\  executable

\ 20221228 tested ant_switcher with transpiled Task2
\ 20221227 began using AI6KG's PWM based ant_switcher correctly
\ 20221223 added quadratic polynomial fitting
\ 20221221 restored sound card reading for real time bearings processing

\ 20221215 corrected kfsqrt and drift issue for zero crossings relative
\ to spikes

\ 20221213 fixed bugs in kfatan2 causing wrong phase angle computation

\ 20221130 changed quadratic polynomial fitting to use the 2nd and 3rd
\ samples back of a spike instead of the 1st and 2nd samples

\ 20221113 replaced linear extrapolation by fitting a quadratic
\  polynomial when smoothing spikes in a copy of the original signal
\  buffer cast as 64-bit float values  

\ 20221016 completed conversion to floating point zero crossing
\  count using linear interpolation

\ 20221011 changed the smoothing method in smooth-the-spikes from
\  averaging of five signal values around each spike to replacing
\  the spike and its 2nd half by linear extrapolation of fitted values
\  based on the last two signal values ahead of the two spike halves
\ 20221011 also provided floating point interpolated estimation of
\  actual spikes' leading edges instead of using each spike's
\  quantized integer valued first peak's sound card sample count to
\  measure the offset in sound card sampling count to the quantized
\  positive zero crossing after it in the smoothed buffer

\ 2022 mid October  Changed using
\  (a) sound card sample count integer values when a FIR filtered Doppler
\      tone crosses zero to a positive value, to
\  (b) a linearly interpolated floating point count between the sound
\      card sample count values just before and after the Doppler tone
\      goes positive

\ 20221010 corrected "after Ant4 off" in getToneOffsetRangeToSearch
\ 20220917 restored initializing C string data part with ASCII 0's
\ 20220916 added trial calibration offset for testing using rdf.kn5r.net
\ 20220909 changed ant rot rate, samples/rotation, sections/batch to
\  values prior to 20220907
\ 20220907 changed ant rot rate, samples/rotation, sections/batch to be
\  compatible with sound card sample count based "timing" of antenna
\  switching and audio "spiking" for a reference pulse
\ 20220906 set update rate at rdf.kn5r.net to once per second
\ 20220905 set up sending raw data to rdf.kn5r.net website 
\ 20220903 removed testing output data file writing because the GFTP
\  failed to allow it
\ 20220815 restored writing out output data files occasionally
\ 20220730 replaced using k<<# .... (added because GFTP lacks <<# etc)
\  by using d>f f>d f/ f* to peel off digits into a string of ASCII chars
\ 20220708 replaced throw by drop in write-out-last-batch-data-to-files
\ 20220707 replaced max by kmax in one place where I didn't notice earlier
\  NOTE: no max in the GFTP, nor fmax
\ 20220701 removed set-mixer action
\ 20220624 fixed bugs in kr> and kfmax
\ 20220623 added kum/mod to complete my replica of Gforth's <# ... #>> 
\  suite of words for number formatted strings missing in the GFTP
\ 20220622 Continued removing all floats in Gforth's format x.xex that
\  the GFTP can't interpret, and remaining usage of ud/mod.
\ 20220617 to 0621 replaced all use of */mod and ud/mod, etc, by only
\  using Forth primitives already in the GFTP.
\ 20220615 restored using */mod for peeling off digits to place in
\  a string for text output
\ 20220614 restored using fatan2 after having redefined it using only
\  words included in the GFTP
\ 20220609 repaired incorrect simulation of <<# <# #s ... #> #>>
\ 20220606 replaced tagging by time&date with utime
\ 20220602 fixed bad mistake at unused6 and unused7
\ 20220531 added Doppler tone peak amplitude to the angle&quality
\  report to assist in better acquisition of weak bearings
\ 20220529 adapted to sending a time&date tag after each batch start
\  and a delta Linux utime from batch start to each batch section
\ 20220528 added sending of relative utime tag after each bearing data
\ 20220522 split off amixer setup from open-sound-card-input into a
\ separate action used only once when starting rfforb or test

\ 20220521 shortened sound card buffer to avoid buffer overflow
\ 20220517 adapted to utilizing Linux pipes as in the Gforth help

\ 20220516 trying to use files to receive bearings data from the
\  FIR filter SW -- that failed to work satisfactorily

\ 20220514 changed to launching this app from a Linux command line
\  to write data to stdout amd Bearings_capture.4th is modified to
\  read the data via stdin.

\ 20220404 changed to using fatan2 when not using the transpiler
\ 20220502 reduced FIR filtering buffers by a signal processing speed
\  factor when not using the transpiler

\ 20220427 Diagnosing segmentation error
\ 20220224 Changed from finding peaks to finding zero crossings.
\ 20220222 Added 1.0e0 to FIR filtered data to facilitate finding peaks.
\ 20220218 corrected failure to initialize FIR filter accumulator and
\  changed rfft to use fscale-fac as an fvariable since the GFTP lacks
\  fconstant

\ Inserted RPiFIRfilter1600Hz220118.4th source code here for use with
\ W6REK's gforth-transpiler which still doesn't have gforth's include.

\ Also did more transpiler compatibility chages here and in pile.py .
\ Added BEGIN WHILE REPEAT to pile.py so we can now use them instead of
\ a finite do loop in rfforb.    20220130

\ 20210814 Revisions were made in March 2021 for the gforth-transpiler
\ but then I concentrated on improving FIR utilization.

\ This "test" code here consists of filter running portions of the code
\ in RPiFIRfilterEvaluation.txt which uses simulated sound card data
\ containing a Doppler tone and another frequency representing a
\ component of other audio that would be present in a typical
\ FM transmission. That allowed confirming expected Doppler tone
\ response from the FIR filter and its supression of audio outside
\ the narrow filter passband.

\ In the "test" code simulated audio is replaced by reading 16-bit audio
\ from a sound card streaming at 48ksps into a short buffer long
\ enough to hold #taps slots of 16-bit data, then casting to IEEE
\ 64-bit floats in a floats buffer. Some extra buffer length is
\ provided to view longer audio streams when wanting to examine
\ captured Doppler tone kerchunks of various durations.

\ The "test" code below includes ability to measure CPU time used per
\ sound card buffer capture at 48ksps.

\ After evaluating ring buffer FIR filtering and passing 16-bit
\ raw and FIR filtered data to a bearings capture test at 48ksps,
\ a different distribution of tasks was expected to be less prone
\ to jitter in sync spike time intervals after viewing recorded
\ 16-bit raw signal files using audacity SW. Apparently at
\ 48ksps, 21us is too short a time to let Linux write output bytes to
\ a file to be read by the 3rd program originally written for bearings
\ acquistion using a Ramsey Electronics DDF-1 and reporting bearings data
\ to an RDF network by packet radio or the internet.

\ In the "test" code the FIR filter is run on a saved ring buffer #taps
\ times N long for N antenna rotation cycles instead of immediately
\ after each sound card audio value was stuffed into the ring
\ buffer. The 16-bit signal values from the sound card are
\ converted to 64-bit floats for FIR filtering as in the FIR evaluation
\ code. The 64-bit raw signal and filtered values are then processed in
\ the test code prior to writing anything out to a file to be read by an
\ adapted version of the bearings capture code written in late 2020.

\ The rfforb code
\ 1. picks off N spikes in an unfiltered audio buffer and
\    N Doppler tone zero upward crossings in a corresponding second buffer
\ 2. computes a sum of phase angle differences represented by
\    differences between spike and tone zero crossing array indeces
\ 3. writes out a value 0 to N*(M-1) K times per second
\    representing an averaged Doppler tone phase angle.
\
\ Currently the fixed parameters are:
\    T = 1 second of signal capture selected to fill a signal
\        buffer for monitoring filtering performance
\    R = 48000 sps reading 8-byte (64-bit) floats from the sound
\        card
\    F = 1600 cps Doppler modulation tone frequency

\ 20230309
\ The actual Doppler tone is closer to 1602 to 1603 Hz now that we
\ use DMA and PWM instead of RPi3B SW timing loops

\ Then we choose how many samples to FIR filter continuously:
\    N = 80 selected antenna rotation cycles for a section of a
\        batch of signal samples to be FIR filtered
\ Then other parameters are determined:
\    M = R/F = 30 audio samples captured at 48ksps in 1 ant rot cycle
\  20230309  The actual number of samples is closer to 29.952 now that we
\     use DMA and PWM instead of RPi3B SW timing loops
\    B = T*R = 48000 = number of signal samples in a batch
\    S = B/(M*N) = 20 = number of buffer sections to be FIR
\        filtered, then have their spike and tone zeros array index
\        differences summed and the sum written out to a file to
\        be read by the Bearings_captureyyyymmdd.4th task
\    K = S/T = 20 = number of phase angle representing messages
\        per second sent to the Bearings_captureyyyymmdd.4th task

\ Originally it was planned to send phase angle representing
\ nibbles nearly 400 times per second, a bit slower than if they were
\ captured nibbles from a Ramsey Electronics DDF-1, but then we would
\ be averaging over 16 samples so the bearing resolution would be
\ greatly improved over the DDF-1's 16 LED's +-11.8 degrees. It was found,
\ however, that sending ~400 messages of 3 text digits plus LF=$0A ~400
\ times per second caused overflow of sound card buffering while
\ doing the required computations and file writing, so it was
\ decided to back off to 50 or fewer messages per second. This would still
\ provide for capturing kerchunks.

\ An alternative idea I considered was to jumper 5 GPIO pins to
\ another set of 5 unused pins. One set would be written to
\ by a version of this code, first writing out the nibble, then
\ after that got stabilized by the RPi, a strobe pin would be
\ raised. Then the suitably adapted bearings capture task would
\ read the nibble after looping on searching for a "strobe" as
\ when a Ramsey Electronics DDF-1 was used with an RPi2B capturing
\ its bearing nibbles and processing data to display bearings.

\ During testing we compile code for filtering with large files
\ of signal and filtered data for evaluation using audacity.

\ This was done until today, 20220130:
\ include RPiFIRfilter1600Hz20220118.4th
\ ." Loaded RPiFIRfilter1600Hz202201118.4th for 385 taps" .s
\ We can't do this when transpiling because it lacks "include".
\ I just realized, however, that the make file can be changed to compile
\ more source files at one time!    20220130

\ Changed FIR filter to 385 taps   20220110
\ Made sampling-interval more precise  20220108

\ 20211131  added a cr after "...IEEE format..." and changed the marker

 marker startover
   \ not needed when transpiling but Henry put in pile.py so we don't
   \ have to keep commenting it off when switching from interactive
   \ development/testing to running optimized tasks on the Pi
    decimal


\ The following are needed when using the GFTP.
 : key 0 ;  : key? 0 ;
 : .s ;  : f.s ;
 : 0> s>d d0> ; \ delete after adding 0> to gforth-transpiler 20220204
 : nip ( n1 n2 -- n2 ) swap drop ;  \  20220606

\ The GFTP lacks f0>, etc, fatan2    20220614
\ but it does have f> f>= f< f<= f<> 20240312 
: f0.0e0 0 s>f ;  
: f0> f0.0e0 f> ;  : f0< f0.0e0 f< ;  : f0>= f0.0e0 f>= ; \ 20240312


\ GFTP also lacks cell and cells
\ 4 constant cell
\ : cells ( n -- n*4 )  cell * ;
\ But GFTP compained about redefinition of 'void F_cells()'

\ : floats 8 * ; \ not in the GFTP    \ 20221016
\ Can't do this! The GFTP complains about a duplicate definition.
\   20221110

: 4* 4 * ;

0 value #taps
 \ will be set to the constant in the first 4 char's of a *.dat
 \ file name
17 constant #digits

\ $7FFFFFFFFFFFFFF = 9223372036854775807
\   max 64-bit signed double has 19 digits

\ 17-digit signed integers occupy 61 significant bits for
\ positive values, and for negative numbers the top bit is set,
\ so only 2 bits are not used in the top nibble.
\ 99999999999999999. hex d. 16345785D89FFFF  ok
\ -99999999999999999. hex d. -16345785D89FFFF  ok

\ The format used in the online FIR design and evaluation tool
\ text window shows each signed decimal number for an FIR
\ coefficient in one line having a total of 17 digits counting
\ non-zero digits ahead of the decimal point and those after it.
\ A negative number is preceded by a minus sign ahead of at
\ least one digit before the decimal point, which is 0 when the
\ 17 significant digits are all after the decimal point.

\ Therefore, all of the information within the FIR coefficients
\ fits within 64 bits, including where the decimal point is.
\ The 2 unused bits could define which of 4 possible different
\ decimal point locations is used in a 17 digit fixed point
\ decimal number used in the FIR coefficient lists I saw so far,
\ eg. Fixed point number in text box   exponent for
\                                      Gforth 17-digit double
\     0.00012345678901234567           -20
\     0.0012345678901234567            -19
\     0.012345678901234567             -18
\     0.12345678901234567              -17
\     1.2345678901234567               -16
\    12.345678901234567                -15
\   123.45678901234567                 -14

\ In this Gforth code we use FIR signed 64-bit coefficients stored as
\ 8-byte records of IEEE 64-bit floating point values.



\ ===============================================================
\ file access words usage references:

\ http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/General
\ -files.htm

\ data-in l#General-files05web

\ http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Files
\ -Tutorial.html#Files-Tutorial

\ file       c-addr u wfam -- wfileid wior
\ open-file       c-addr u wfam -- wfileid wior
\ wfam = file access method, options: w/o r/o r/w bin
\ https://www.cs.rit.edu/~bks/common/gforth/General
\ -files.html#General%20files

: 8* 8 * ; \ 20220130

\ GFTP compained about redefinition of 'void F_cells()'
0 value coeffs-fid    8 constant coeff-len
create coeffs-data-file-name 256 allot

25 constant max-coeffs-data-#taps-len

create coeffs-data-#taps-string
  max-coeffs-data-#taps-len 1+  allot

create coeffs-data-path-name  128 allot

: set-coeffs-data-path-name
    coeffs-data-path-name 128 erase
    s" ./" coeffs-data-path-name place
    ;


: set-coeffs-data-#taps-string
    coeffs-data-#taps-string  max-coeffs-data-#taps-len 1+ erase
    311 to #taps   s" 0311tapsFIRfiltercoeffs"     \ 20221211
    ( str_adr cnt ) coeffs-data-#taps-string +place
   ;

: set-coeffs-data-file-name
    coeffs-data-file-name 256 erase
    coeffs-data-path-name count  coeffs-data-file-name  place
    coeffs-data-#taps-string count  coeffs-data-file-name +place
    s" .dat" coeffs-data-file-name +place
    ;

: open-coeffs-data-file
    set-coeffs-data-path-name
    set-coeffs-data-#taps-string
    set-coeffs-data-file-name
    coeffs-data-file-name count 2dup  r/o
    open-file ( adr len fileid wior )
    if
        cr ." File "   ( adr len fileid=0 ) drop  type  quit
        ."  doesn't exist "
    else
            \ file was opened
            ( adr len fileid ) to coeffs-fid
            ( adr len )
          \  cr ." FIR coefficients will be loaded from " type
            2drop \ 20220519
    then
    ;

: close-coeffs-data-file  coeffs-fid close-file ( wior ) throw ;

 open-coeffs-data-file

\ NOTE: #taps is set when the user enters a coefficients
\       file name before the arrays below are allocated.
\       Coefficient .dat files are created by compiling
\       and running FIRcoeffsTXTtoDATfilexx-xx.txt .

 \ Without using Gforth's defining words variable, 2variable fvariable
 \ before defining arrays, segmentation error occurs unless the array
 \ begins at a appropriate memory address alignement address.

\ This array stores a list of 64-bit doubles followed by a byte
\ holding an 8-bit power-of-10 exponent constant.
\ #taps #digits ( 17 ) 7 + *  \ maintain 64-bit allignment
\ constant coeffs-fixed-point-mantissa-array-len
\ 2variable unused1 create coeffs-fixed-point-mantissa-array
\  coeffs-fixed-point-array-len allot

#taps 8*  \ this array must maintain 64-bit allignment for the
          \ coefficient mantissas 20221228
 constant coeffs-fixed-point-mantissa-array-len
2variable unused1 create coeffs-fixed-point-mantissa-array
  coeffs-fixed-point-mantissa-array-len allot

\ A separate array for the coefficient exponents is needed
\ This one is just a byte array.  292221228 
create coeffs-fixed-point-exponent-array
  #taps allot

: view-fixed-point-coeffs
    #taps 0
    do
        cr coeffs-fixed-point-mantissa-array i 8* + 2@ 2dup d0>
        if ." +" then  d. ."  exp:"
        coeffs-fixed-point-exponent-array i + c@ negate .
    loop ;
: vfpc  view-fixed-point-coeffs ;

\ : load-coeffs-from-file-to-fixed-point-array
\    coeffs-fixed-point-array coeffs-fixed-point-array-len
\    coeffs-fid  read-file
\    ( #bytes_read wior )
\    if
\        cr ." FILE READ ERROR!" drop
\    else
\        drop    \ 20220510
\        close-coeffs-data-file
\    then
\    ;

create exponent-byte  1 allot

: load-coeffs-from-file-to-fixed-point-arrays  \ 20221228
  #taps 0
  do
    coeffs-fixed-point-mantissa-array i 8* + 8
    coeffs-fid  read-file
    ( #bytes_read wior )
    if
        cr ." MANTISSA READ ERROR!" drop
    else
        drop  exponent-byte 1 coeffs-fid read-file
        ( #bytes=1 wior )
        if
            cr ." EXPONENT READ ERROR!" drop
        else
            drop  exponent-byte c@
            coeffs-fixed-point-exponent-array i + c!
        then
    then
  loop
  close-coeffs-data-file ;

4 constant S16stereo-data-len \ 16-bit data from stereo channels 20230417
8 constant filtered-buf-data-len
8 constant signal-float-data-len   \ 02-26'21

#taps filtered-buf-data-len * constant coeff-floats-array-len
\ This array must by 64-bit boundary aligned:
fvariable unused2 create coeff-floats-array
 coeff-floats-array-len allot
\ Use appropriate defining word instead of just create
\ for proper memory alignment.  An off proper alignment memory
\ will cause at least run time slowing down or even memory
\ access crashes. 

: f10 10 s>f ;  \ The GFTP lacks fconstant  20220731

: convert-fixed-point-to-float-coeffs
   \ utime
   \ for debugging, remove when piping to Bearings_capture   22020511
    #taps 0
    do
        coeffs-fixed-point-mantissa-array i 8* + ( adr ) 2@  d>f
        ( adr | mantissa ) f10
        coeffs-fixed-point-exponent-array i + c@ s>f  fnegate
        ( -- | mantissa 1.0e1 E=-exponent_from_T-filter_file )
        f**
        \ f**  r1 r2 – r3  float-ext  “f-star-star”
        \ r3 is r1 raised to the r2th power.
        ( -- | mantissa 10^E ) f*
        ( -- | IEEE_format_floating_point_coefficient )
        coeff-floats-array i 8* + f!
    loop
   \ utime  remove when piping to Bearings_capture  22020511
   \ or doing stdout to rdf.kn5r.net    20221229
    \ cr ." Conversion to IEEE format took "
    \ 2swap d-  d. ." usecs" cr
    ;
\ when debuggibg:
 : cfptfc convert-fixed-point-to-float-coeffs ;
 : dctptfc break: convert-fixed-point-to-float-coeffs ;

: view-coeffs-fixed-point-array
    cr ." vcfpa:"
    cr #taps 0
    do
        i  5 mod 0= if cr then
        coeffs-fixed-point-mantissa-array i 8* + 2@ d.
        coeffs-fixed-point-exponent-array i + c@ .
    loop ;
: vcfpa  view-coeffs-fixed-point-array ;

: view-coeff-floats-array
    cr ." vcfa:"
    coeff-floats-array  #taps  0
    do
        i  5 mod 0= if cr then
        ( adr ) dup  f@  f.  ( adr ) 8 +
    loop  drop ;
: vcfa  view-coeff-floats-array ;

: LoadCoeffs&CastToFloats
   load-coeffs-from-file-to-fixed-point-arrays \ 20221229
   convert-fixed-point-to-float-coeffs ;

LoadCoeffs&CastToFloats

\ FIR filter algorithm

\ Sound card parameters
fvariable fsampling-rate ( bps )
48000 s>f fsampling-rate f! \ = 48kbps

fvariable fsampling-interval ( us )  \ 20220106
1000000 s>f fsampling-rate f@ f/  fsampling-interval f!
 \ 20.83333 us

\ Antenna switching parameters before AI6KG provided a very stable
\ antenna switcher.
\ 1600 constant tone-freq ( Hz )
\ 1000000 tone-freq / ( usecs ) constant tone-cycle-period ( us )
 \ 625 us

\ Using AI6KG's DMA and PWM based ant_switcher task:
624 constant tone-cycle-period \ 20230309
\ NOTE: The new antenna switcher needed a slight change to be
\       compatible with the DMA and PWM antenna switching method
\       for even division by 4.
fvariable ftone-freq 1000000 s>f tone-cycle-period s>f f/
( 1602.5641025641 )
 fdup ftone-freq f! f>s 1+ constant tone-freq
  \ rounded up to 1603 Hz

fsampling-interval f@ ( us ) #taps s>f f* f>s \ 20220106
tone-cycle-period +  ( us ) constant FIR-signal-history-us
 \ 7103 us
\ history of samples needed ahead of a series of samples to
\ be filtered

fsampling-rate f@ ( Hz ) FIR-signal-history-us s>f f* f>s
 \ 20220106
 1000000 ( ms/sec ) / constant #FIR-samples

\ fsampling-rate f@ f>s tone-freq /  \ 20220106
\ ( 30 ) constant #samples/tone-cycle
fvariable fsamples/tone-cycle
fsampling-rate f@  ftone-freq f@ f/ fsamples/tone-cycle f!
 \ ~29.952 20230310

30 constant #samples/tone-cycle
\ rounded up from 29.952 for use in allocating buffers  20230309
\ Running view-spikes&zeros when debugging reveals varying counts
\ near 30 due to the asynchronous sound card and RPi PWM clocks

tone-freq 2 *  constant #extra-tone-cycles
\ we use a 311 taps FIR filter but we provide for one extra second of
\ stored signal for evaluation wwith audacity

#extra-tone-cycles #samples/tone-cycle * constant #extra-samples
#FIR-samples #extra-samples + constant #total-test-samples

 #total-test-samples filtered-buf-data-len *
   constant filtered-buffer-len   \ for 64-bit floats
 #total-test-samples S16stereo-data-len ( 4 ) *
 \ 16-bit data from stereo channels
   constant  S16signal-buffer-len
 #total-test-samples signal-float-data-len *
   constant  signal-buffer-len \ 02-25'21

\ variable signal-buffer  signal-buffer-len allot
\ Thas caused illegal memory boundary issues.  W6REK suggested the
\ following trick:
variable unused3 create S16signal-buffer
  S16signal-buffer-len allot \ 02-25'21
  S16signal-buffer  S16signal-buffer-len erase

fvariable unused4 create signal-buffer
  signal-buffer-len allot  \ 02-25'21
  signal-buffer  signal-buffer-len erase

fvariable unused5 create filtered-buffer
  filtered-buffer-len allot
  filtered-buffer  filtered-buffer-len erase

\ We use an appropriate defining word instead of "create"
\ for proper memory alignment.  An off proper alignment memory
\ will cause at least run time slowing down or possibly memory
\ access crashes.

\ In real time sound card data capturing, signed 16-bit data is
\ converted to floats on the fly while FIR filtering because
\ apparently cheap sound cards like those we are using are
\ incapable of actually outputting floats with the -f F64_LE
\ parameter for arecord.

fvariable FIR-filtered-value

0 value tap-ptr  0 value signal-buffer-ptr

0 value filter-input-ptr  0 value filtered-buffer-ptr
  \ Used as FIR filter pointers while running the FIR filter.

: view-S16signal-buffer  ( hi_samp# lo_samp# )
    do
        i 10 mod 0= if cr then
        S16signal-buffer i 2 * + w@  .
    loop ;
: vS16b view-S16signal-buffer ;

: view-signal-buffer ( hi_samp# lo_samp# )
    do
       i 5 mod 0= if cr then
       signal-buffer i signal-float-data-len * + f@  f.
    loop ;
: vsb view-signal-buffer ;

: view-filtered-buffer  ( hi_samp# lo_samp# )
    do
        i 5 mod 0= if cr then
        filtered-buffer i filtered-buf-data-len * + f@  f.
    loop ;
: vfb view-filtered-buffer ;


\ ==============================================================
\ This FIR filter implementation is based on
\ run-FIR-on-signal-buffer in RPiFIRfilterEvaluation.txt and
\ is adapted for decimated real time signal processing if
\ the chosen number of taps requires more CPU time than
\ the available 21us between sound card reads at 48kbps.

0 value sound-card-fid

: open-sound-card-input
 \ This was done for a mono sound card before switching to a stereo card:
   \ s" arecord -q -D $(arecord -L | grep '^default') -c 1 -r 48000 -f
   \ S16_LE"
   \ s" arecord -q -D hw:CARD=dongle -c 1 -r 48000 -f S16_LE"
    s" arecord -q -D hw:CARD=dongle -c 2 -t raw -r 48000 -f S16_LE"
    \ for the stereo card 20230214
    ( adr #bytes ) r/o open-pipe ( fid wior )
    if
        cr ." Failed to open pipe from sound card" drop quit
    else
        ( fid ) to sound-card-fid
    then ;
: osci open-sound-card-input ;

: close-sound-card-input sound-card-fid 0<>
    if
        sound-card-fid close-file ( wior )
        if
            cr ." Failed to close sound card input"
       \ else
       \     cr ." Sound card input has been terminated"
        then
    else
        cr ." null sound-card-fid" cr
        ." There may have been sound card opening failure!"
    then ;
: csci close-sound-card-input ;

0 value S16-data-fid
0 value orig-data-fid   0 value spike-data-fid   0 value filt-data-fid

: data-files-path  s" ./" ;

create data-files-path-name  80 allot

data-files-path data-files-path-name place

create S16-data-file-name  200 allot
FALSE value data-read-from-stereo-S16file?

: open-selected-S16stereo-data-file
     \ s" Wouxun KG-UV3D 10ft away 16kbps stereo 440.800 test2.raw"
     \ s" AI6KGtest-2023-04-10-ft-70d.raw" \ 20230412
      s" S16-data-fileKERCH'S.raw" \ 20240210
     \ s" S16-data-file20240223.raw" \ 20240223
     \ s" S16-data-file202403091147.raw" \ 20240309
      S16-data-file-name place
      S16-data-file-name count r/o open-file ( fid wior )
      if
        cr ." No such file:" S16-data-file-name count type quit
      then
    ( fid ) to S16-data-fid
  ;

: close-S16stereo-data-file
    S16-data-fid 0<>
    if
        S16-data-fid close-file ( wior )
        if
            cr ." Failed to close S16 data file"
        else
            0 to S16-data-fid
        then
    else
        cr ." Null fid for S16 data file"
    then
  ;

create $utime 17 allot   16 $utime c!

: open-S16stereo-data-file
   \ When developing tasks A, B, C, D, we first need to set
   \ data-read-from-stereo-S16file? to FALSE. Then we run TaskA once
   \ to prepare an S16stereo file that TaskA writes out to disk in r/w
   \ mode. Then for testing and debugging we rename the file to what is
   \ the file name in open-selected-S16stereo-data-file.

   \ While debugging the four tasks and testing their performance
   \ with data-read-from-stereo-S16file? set to TRUE, we read pre-
   \ recorded audio from a selected file in r/o mode.
\    data-read-from-stereo-S16file?
\    if
      open-selected-S16stereo-data-file
\    else  
      \ TaskA will open or create a S16stereo data file for spliting up
      \ into four S16stereo buffer quarters.
      \ The first quarter will be processed here in TaskA and the
      \ remaining 3/4ths of the S16 stereo buffer will be written out
      \ to files for tasks B, C and D to read S16 data and process.
      data-files-path-name count S16-data-file-name place
      s" S16-data-file" S16-data-file-name +place
      s" .raw" S16-data-file-name +place
      S16-data-file-name count r/w open-file ( fid wior )
      ( fid wior )
      if
        ( fid wior<>0 ) -536 <>
        if
            S16-data-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                S16-data-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
      then  ( fid ) to S16-data-fid
\    then
  ;

fvariable fscale-fac  32767 s>f  fscale-fac f!
 \ for converting 16bit ints to 64bit floats

fvariable fscale-fac1 5 s>f fscale-fac1 f! \ 20230311
 \ for desired Dopler tone amplitude when viewing with audacity

$10000 constant 2^16   $8000 constant 2^15
48 constant data-file-name-len \ 20230821

create orig-data-file-name  data-file-name-len allot
create spike-data-file-name data-file-name-len allot
create filt-data-file-name data-file-name-len allot

S16-data-file-name data-file-name-len erase
spike-data-file-name data-file-name-len erase
orig-data-file-name data-file-name-len erase
filt-data-file-name data-file-name-len erase

create $digits  16 allot   0 value #chars  \ 20220731

: peel-off-digits ( d n -- )  \ 20220730
  \ Place n ASCII characters in the $digits string, starting with
  \ putting the LSD at the tail end of the string, and proceed
  \ placing leading 0's if needed to fill out the string.
    ( d n ) to #chars ( d ) d>f  #chars 0
    do
      ( | fval ) fdup f10 f/ ( | fval fval/10 )  f>d d>f
      ( | fval fval/10 ) f10 f*
      ( | fval [fval/10]*10 ) fover fswap f-
      ( | fval frem=fval-[fval/10]*10 ) f>s 48 +
      ( ASCIIchar | fval ) $digits #chars 1- +  i -  c!
      ( fval )  f10 f/ f>d d>f
      ( | fval/10 )
    loop  fdrop
    ;

: peel-off-signed-digits ( d n -- )  \ 20220730
    ( d n ) to #chars
  \ First check if the number d is negative, and if so, negate
  \ the number d and place a minus sign at the start of $digits.
  \ Otherwise, place a + sign there.
    ( d ) 2dup d0< if dnegate 45 else 43 then $digits c!
  \  Place n ASCII characters in the $digits string, starting with
  \ putting the LSD at the tail end of the string, and proceed placing
  \ leading 0's going backwards if needed to fill out the string up
  \ to the sign character.
    ( d ) d>f  #chars 1+ 0
    do
      ( | fval ) fdup f10 f/ ( | fval fval/10 )  f>d d>f
      ( | fval fval/10 ) f10 f*
      ( | fval [fval/10]*10 ) fover fswap f-
      ( | fval frem=fval-[fval/10]*10 ) f>s 48 +
    \ ( ASCIIchar | fval ) $digits #chars 1- +  i -  c!
      ( ASCIIchar | fval ) $digits 1+  #chars +  i -  c!
      ( fval )  f10 f/ f>d d>f
      ( | fval/10 )
    loop  fdrop
    ;

create S16toTaskB-file-name 80 allot S16toTaskB-file-name 80 erase
create S16toTaskC-file-name 80 allot S16toTaskC-file-name 80 erase
create S16toTaskD-file-name 80 allot S16toTaskD-file-name 80 erase
create TaskAavgstoTaskD-file-name 80 allot
 TaskAavgstoTaskD-file-name 80 erase
create TaskBavgstoTaskD-file-name 80 allot
 TaskBavgstoTaskD-file-name 80 erase
create TaskCavgstoTaskD-file-name 80 allot
 TaskCavgstoTaskD-file-name 80 erase

0 value S16toTaskB-data-fid
0 value S16toTaskC-data-fid
0 value S16toTaskD-data-fid
0 value TaskAavgstoTaskD-data-fid
0 value TaskBavgstoTaskD-data-fid
0 value TaskCavgstoTaskD-data-fid

: open-data-to-TaskB,C,D-files
   \ utime 16 peel-off-digits
   \ $digits $utime 1+ 16 cmove
   \ utime will be used only in TaskD to tag the output string
   \ piped to www.rdf.kn5r.net   20230824

   \ The first time TaskA is run the following files will be
   \ created if they were not found using the current directory
   \ and device.
   \ Normally the four concurrent tasks will be written to at their
   \ start after being opened. 
    data-files-path-name count S16toTaskB-file-name place
    s" S16toTaskB-data-file" S16toTaskB-file-name +place
    s" .dat" S16toTaskB-file-name +place
    S16toTaskB-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <>
        if
            S16toTaskB-file-name count r/w create-file
            ( fid wior )
            if
               cr ." Failed to create "
                S16toTaskB-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to S16toTaskB-data-fid

    data-files-path-name count S16toTaskC-file-name place
    s" S16toTaskC-data-file" S16toTaskC-file-name +place
    s" .dat" S16toTaskC-file-name +place
    S16toTaskC-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <> \ see comment above re "once only"
        if
            S16toTaskC-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                S16toTaskC-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to S16toTaskC-data-fid

    data-files-path-name count S16toTaskD-file-name place
    s" S16toTaskD-data-file" S16toTaskD-file-name +place
    s" .dat" S16toTaskD-file-name +place
    S16toTaskD-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <> \ see comment above re "once only"
        if
            S16toTaskD-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                S16toTaskD-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to S16toTaskD-data-fid

    data-files-path-name count TaskAavgstoTaskD-file-name place
    s" TaskAavgstoTaskDfile" TaskAavgstoTaskD-file-name +place
    s" .txt" TaskAavgstoTaskD-file-name +place
    TaskAavgstoTaskD-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <> \ see comment above re "once only"
        if
            TaskAavgstoTaskD-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                TaskAavgstoTaskD-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to TaskAavgstoTaskD-data-fid

    data-files-path-name count TaskBavgstoTaskD-file-name place
    s" TaskBavgstoTaskDfile" TaskBavgstoTaskD-file-name +place
    s" .txt" TaskBavgstoTaskD-file-name +place
    TaskBavgstoTaskD-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <> \ see comment above re "once only"
        if
            TaskBavgstoTaskD-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                TaskBavgstoTaskD-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to TaskBavgstoTaskD-data-fid

    data-files-path-name count TaskCavgstoTaskD-file-name place
    s" TaskCavgstoTaskDfile" TaskCavgstoTaskD-file-name +place
    s" .txt" TaskCavgstoTaskD-file-name +place
    TaskCavgstoTaskD-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <> \ see comment above re "once only"
        if
            TaskCavgstoTaskD-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                TaskCavgstoTaskD-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to TaskCavgstoTaskD-data-fid
  ;
: odtof open-data-to-TaskB,C,D-files ;
\ : dodtof break: open-data-to-TaskB,C,D-files ;

: close-data-toTasksB,C,D-files  \ 20230821
    S16toTaskB-data-fid 0<>
    if
        S16toTaskB-data-fid close-file ( wior )
        if
            cr ." Failed to close S16toTaskB-data output"
        else
            0 to S16toTaskB-data-fid
        then
    else
        cr ." Null fid for S16toTaskB-data file"
    then

    S16toTaskC-data-fid 0<>
    if
        S16toTaskC-data-fid close-file ( wior )
        if
            cr ." Failed to close S16toTaskC-data output"
        else
            0 to S16toTaskC-data-fid
        then
    else
        cr ." Null fid for S16toTaskC-data file"
    then

    S16toTaskD-data-fid 0<>
    if
        S16toTaskD-data-fid close-file ( wior )
        if
            cr ." Failed to close S16toTaskD-data output"
        else
            0 to S16toTaskD-data-fid
        then
    else
        cr ." Null fid for S16toTaskD-data file"
    then

    TaskAavgstoTaskD-data-fid 0<>
    if
        TaskAavgstoTaskD-data-fid close-file ( wior )
        if
            cr ." Failed to close TaskAavgstoTaskD-data output"
        else
            0 to TaskAavgstoTaskD-data-fid
        then
    else
        cr ." Null fid for TaskAavgstoTaskD-data file"
    then

    TaskBavgstoTaskD-data-fid 0<>
    if
        TaskBavgstoTaskD-data-fid close-file ( wior )
        if
            cr ." Failed to close TaskBavgstoTaskD-data output"
        else
            0 to TaskBavgstoTaskD-data-fid
        then
    else
        cr ." Null fid for TaskBavgstoTaskD-data file"
    then

    TaskCavgstoTaskD-data-fid 0<>
    if
        TaskCavgstoTaskD-data-fid close-file ( wior )
        if
            cr ." Failed to close TaskCavgstoTaskD-data output"
        else
            0 to TaskCavgstoTaskD-data-fid
        then
    else
        cr ." Null fid for TaskCavgstoTaskD-data file"
    then
    ;
: cdtof close-data-toTasksB,C,D-files ;
\ : dcdtof break: close-data-toTasksB,C,D-files ;

: open-data-output-files
    utime 16 peel-off-digits
    $digits $utime 1+ 16 cmove
    data-files-path-name count orig-data-file-name place
    s" orig-data-file" orig-data-file-name +place
    $utime count orig-data-file-name +place
    s" .raw" orig-data-file-name +place
    orig-data-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <>
        if
            orig-data-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                orig-data-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to orig-data-fid

    data-files-path-name count spike-data-file-name place
    s" spike-data-file" spike-data-file-name +place
    $utime count spike-data-file-name +place
    s" .raw" spike-data-file-name +place
    spike-data-file-name count r/w open-file ( fid wior )
    ( fid wior )
    if
        ( fid wior<>0 ) -536 <>
        if
            spike-data-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                spike-data-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to spike-data-fid

    data-files-path-name count filt-data-file-name place
    s" filt-data-file" filt-data-file-name +place
    $utime count filt-data-file-name +place
    s" .raw" filt-data-file-name +place
    filt-data-file-name count r/w open-file ( fid wior )
    if
        ( fid=0 wior<>0 ) -536 <>
        if
            filt-data-file-name count r/w create-file
            ( fid wior )
            if
                cr ." Failed to create "
                filt-data-file-name count type
                ( fid=0 ) drop quit
            then ( fid )
        then ( fid )
    then  ( fid ) to filt-data-fid
    ;
 : odof open-data-output-files ;
 : dodof break: open-data-output-files ;

: close-data-output-files
    orig-data-fid 0<>
    if
        orig-data-fid close-file ( wior )
        if
            cr ." Failed to close signal data output"
        else
            0 to orig-data-fid
        then
    else
        cr ." Null fid for signal data file"
    then

    spike-data-fid 0<>
    if
        spike-data-fid close-file ( wior )
        if
            cr ." Failed to close spike signal data output"
        else
            0 to spike-data-fid
        then
    else
        cr ." Null fid for spike signal data file"
    then

    filt-data-fid 0<>
    if
        filt-data-fid close-file ( wior )
        if
            cr ." Failed to close filter data output"
        else
            0 to filt-data-fid
        then
    else
        cr ." Null fid for filtered data file"
    then
    ;
: cdof close-data-output-files ;
: dcdof break: close-data-output-files ;

80 constant #batch-section-ant-rot-cycles \ 20220909
20 constant #batch-buf-sections  \ 20220909

\ We proceed with continuous FIR filtering and suffer only a brief loss
\ of bearings capture while the sound card is read for #taps samples to
\ provide history for FIR filtering, but this happens only at the start
\ of the first section of a batch of sound card samples.

8 constant filtered-data-len

#samples/tone-cycle ( 30 ) \ chosen value, but now using AI6KG's
\ ant_switcher DMA based app the 624us vs former 625us ant rotation
\ interval makes the Doppler tone freq slightly higher, 1602.5641025641
 signal-float-data-len ( 8 ) *
  constant #ant-rot-cyc-bytes ( 240 )

#taps S16stereo-data-len ( 4 ) *  ( 311*4=1244 ) \ left and right channels
  constant #FIRfilter-history-stereo-data-bytes
#taps signal-float-data-len *  ( 311*8=2488 )  \ 20220907
  constant #FIRfilter-history-float-data-bytes

 #samples/tone-cycle ( 30 ) #batch-section-ant-rot-cycles ( 80 ) *
  constant total-batch-section-samples ( 2400 )   \ 20220502
\ The sound card rate is 48kbps   20220907
\ NOTE: This is the number of samples at 48kbps that we would
\ like to process, but unfortunately without the transpiler
\ gforth-fast isn't fast enough to go "full throttle" with the
\ FIR filter in real time, so a number of various
\ #batch-section-samples-to-process values were
\ tried.

\ number of samples to filter must be reduced by signal processing speed
\ factor when not using the gforth transpiler
\ total-batch-section-samples 1 15 */ ( 160 )  \ 20220521
\ total-batch-section-samples 1 6 */  ( 400 )  \ 20220722
\ total-batch-section-samples 1 5 */  ( 480 )  \ 20220522
\ total-batch-section-samples 1 4 */  ( 600 )  \ 20220522
\ total-batch-section-samples 2 7 */  ( 685 )  \ 20220502
\ total-batch-section-samples 1 3 */  ( 800 )  \ 20220522
\ total-batch-section-samples 1 2 */ ( 1200 )  \ 20220709

\ After fixing all transpiler related bugs a larger fraction of sound card
\ samples was possible to process.
\ total-batch-section-samples 3 4 */ ( 1800 )  \ 20220720
\ total-batch-section-samples 11 16 */  \ 20220722
\ total-batch-section-samples 7 8 */ ( 2400*7/8=2100 ) \ 20220819
\ total-batch-section-samples 15 16 */ ( 2400*15/16=2250 )
 total-batch-section-samples ( 2400 )
  constant #batch-section-samples-to-get
   \ value chosen so it takes just under 1 second for processing all
   \ signal data for the selected number of sections of a selected
   \ batch size lasting 1 second.

600 constant #batch-section-samples-to-process
 \ 1/4th of the 16bit stereo buffer is processed by each of 4 concurrent
 \ tasks in separate ARM processor cores \  20230816
   \ Signal data processing deals with one section of the batch at a
   \ time to
   \ (a) locate the spikes cast to 64-bit floats in the spike buffer
   \ (b) smooth out the spikes in a copy of the signal buffer
   \ (c) find the the zero crossings between the spike locations 
   \ (d) run the FIR filter on the smoothed signal data
   \ (e) compute each Doppler tone phase angle at each antenna
   \     rotation as a unit vector in an x-y plane, whose angle
   \     clockwise from the x axis is the measured phase angle
   \ (f) Compute the average Doppler tone phase angle as the sum of
   \     those vectors divided by the number of zero crossings found.
   \     This average is a bearing qualification factor during that
   \     section of the batch, i.e., when the bearing is constant this
   \     value is 1 and when the more bearings are random, as for pure
   \     white noise received, the closer this value approaches 0.

   \ (g) Attach the utime divided by 1000 as milliseconds end of
   \     each batch section and send it along with the average Doppler
   \     tone phase angle value and average vector magnitude via stdout.

\ #taps #samples/tone-cycle /  #taps #samples/tone-cycle mod 0= 0= 1 and +
\ ( 13 ) \ 20230202
\ adjustment for #samples/tone-cycle no longer being exactly 30   20230310
#taps s>f fsamples/tone-cycle f@ f/ ( 10.3666... ) f>s ( 10 ) 1+
\ bumped up enough to have adequate rotation cycles ahead of where the
\ FIR filter starts MAC operations
 constant #FIR-history-ant-rot-cycles ( 11 )  \ 20230312

#taps ( 311 ) S16stereo-data-len ( 4 ) * \ 1244
 constant #FIR-history-ant-rot-S16bytes
#taps ( 311 ) S16stereo-data-len ( 8 ) * \ 2488
 constant #FIR-history-ant-rot-float-bytes

\ NOTE: We filter only the signal samples after the initial history
\ of #taps samples, but we also need to smooth out the spikes in the
\ first #taps samples part of the original 64-bit signal data because
\ they will otherwise "pull" the Doppler tone phase angle towards the
\ spike's reference phase angle = 0.

\ For the 19 batch sections after the first one we filter using already
\ smoothed 311 samples from the previous batch section data as history
\ that the FIR filter uses before it reaches sample number 311 in it.

#batch-section-samples-to-get  S16stereo-data-len ( 4 ) *
 constant #batch-section-stereo-bytes-to-read-from-card-or-file
  \ to read from the sound card as 16-bit signed integers for each
  \ batch section, or from a precorded sound card capture file

#batch-section-stereo-bytes-to-read-from-card-or-file
 #batch-buf-sections *
 constant S16stereo-signal-buffer-len

#batch-section-samples-to-get ( 2400 ) signal-float-data-len *
 constant #batch-section-float-bytes \ 2400*8=19200
 \ #bytes used by
 \ do-offset-to-batch-sec-float-data
 \ last-section-sig-buf-history-start
 \ write-out-last-batch-data-to-TaskB,C,D-files

#batch-section-samples-to-get ( 2400 ) signal-float-data-len *
 #batch-buf-sections ( 8 ) * ( 348000 )
 constant orig-signal-buffer-len 
\ Total number of bytes converted to floats for the total of all the
\ batch sections of an rffobsbs run.

\ An extra buffer is needed for right channel 64-bit signal data
\ containing only spikes
orig-signal-buffer-len #FIRfilter-history-float-data-bytes +
constant orig-signal-buffer-extra-len

fvariable unuse13 create spike-buffer
 orig-signal-buffer-extra-len allot
 spike-buffer orig-signal-buffer-extra-len erase
 spike-buffer orig-signal-buffer-extra-len +
 constant spikebufend

\ : spikebufput ( adr | fval -- ) \ 20230702
\    dup  spike-buffer <  over spikebufend >= or
\    if cr . ." IS AT OR PAST THE END OF SPIKEBUF!" . quit
\    else f! then ;\

0 value batch-sec#  0 value batch#

#batch-section-ant-rot-cycles ( 80 ) #FIR-history-ant-rot-cycles
 ( 13 ) + ( 93 ) 25 + \ allow for extra unexpected spikes
 ( 118 ) constant spike&zero-array-len
 \ number of array float size (8 byte) slots

\ NOTE: Now that we stopped using "busy loops" for timing the above
\ concern is no longer a big problem. Sound card sample counting is very
\ stable, as seen using an oscilloscope.

\ This array stores which sample number n within a batch section holds
\ the n-th sync spike, where n-1 is the index into this array.
 variable unused6 create spike-loc-in-sig-buf
  spike&zero-array-len 4* allot
  spike-loc-in-sig-buf  spike&zero-array-len 4* erase
  spike-loc-in-sig-buf  spike&zero-array-len 4* +
 constant slisbufend

: slisbufput ( n slisbufadr -- ) \ 20230702
    dup  spike-loc-in-sig-buf <  over slisbufend >= or
    if cr . ." IS AHEAD OR PAST END OF SLISBUF!" . quit
    else ! then ;

\ This array stores which sample number n within a batch section holds
\ the n-th Doppler tone zero crossing, where n-1 is the index into this
\ array.
variable unused7 create neg-to-pos-loc-in-FIR-buf
  spike&zero-array-len 4* allot
  neg-to-pos-loc-in-FIR-buf  spike&zero-array-len 4* erase
\  neg-to-pos-loc-in-FIR-buf  spike&zero-array-len 4* +
\ constant ntplifbufend

\ : ntplifbufput ( n ntplifbufadr -- ) \ 20230702
\    dup  neg-to-pos-loc-in-FIR-buf <  over ntplifbufend >= or
\    if cr . ." IS AHEAD OR PAST END OF NTPLIFBUF!" . quit else ! then ;

\ Up to 20221017 the above two arrays were being filled for each
\ batch section by the array index of a spike location in the
\ signal buffer buffer array subtracted from the index of the next
\ Doppler tone zero crossing index in the FIR filtered buffer.
\ This index difference is proportional to the Doppler tone phase angle.
\ By scaling up that integer appropriately, a Doppler tone phase angle
\ was derived for each antenna rotation.

\ After 20221017 we upgraded the above phase angle calulation to higher
\ precision as follows:
\ (a) Using linearly extrapolated original signal buffer values from two
\     sound card samples back of the first spike sudden rise in the
\     original unsmoothed signal buffer, the function smooth-the-spikes
\     first linearly extrapolated the values the original would have had
\     at the sample counts of the two "spike half" peak values if no
\     spikes had been mixed into the audio stream from the receiver.
\     That gave us a "baseline" at each spike half event for measuring
\     heights of the spike halves.
\ (b) We then subtracted the two baseline values from the sound card
\     measured spike half values to get two spike half amplitudes. Then
\     we did a quadratic Lagrange polynomial fit of two simulated spike
\     half heights above their baseline values. The polynomial fit used
\     three sound card sample numbers as X-axis values, at the sample
\     back of the 1st spike half and at each spike half event. The
\     corresponding Y-values for fitting a quadratic y=a*x^2 + b*x + c
\     were
\     (1) the signal value at the samples back of the 1st spike half,
\     (2) the amount of rise of the 1st spike half above its linearly
\         extrapolted baseline at that sample count
\     (3) the amount of rise of the 2nd spike half above its linearly
\         extrapolted baseline at that sample count.
\     This simulates how the spike halves would have appeared if the
\     signal from the receiver was turned off.
\ (c) We then computed a linearly interpolated real number for
\     representation of an interpolatted "count" for the leading edge
\     of the actual spike event, based proportionally on
\    (1) the amplitudes of the two sound card sampled spike levels above
\        the baseline, and
\    (2) the assumption that spike pulse heights above their simulated
\        baseline are measured by the sound card proportionally to their
\        percentage of time overlapping the sound card 625us sampling
\        window.
\ (c) For the FIR filtered Doppler tone neg to pos zero crossings, we
\     computed a linearly interpolated real number of an estimated
\     interpolated "count" for the actual zero crossing event, based
\     proportionally on the amplitudes of the adjacent neg and pos sound
\     card sampled levels.

\ FIR filtered Doppler tone neg to pos crossing interpolated "counts" are
\ stored in a float array spike-loc-in-interpolated-counts and
\ interpolated spike "counts" are stored in another float array
\ tone-neg-to-pos-interpolated-counts. To access the "count" value for
\ a spike or zero crossing, one goes to the location index of that
\ spike or zero crossing in the array for it defined below.

\ Further descriptive comments are in the interpolate-spike-counts and
\ find-Doppler-tone-neg-to-pos-crossings functions.

\ NOTE: After the change to using a stereo sound card, the function
\  smooth-the-spikes was replaced by interpolate-spike-counts which does
\  mostly the same computations but no longer needs to replace sound card
\  spike values in smooth-buffer, which was initially copied from the
\  signal-buffer. Instead, using a stereo card we write into spike-buffer
\  the spike signal values read from the right stereo channel and cast
\  them as floats there. The "base line" in spike-buffer has small decay
\  of signal between spikes, so most interpolation steps in the former
\  function smooth-the-spikes are included in interpolate-spike-counts,
\  except there is no longer a need to replace signal buffer values at
\  the spikes with smoothed values because the stereo sound card records
\  signal values separateely from its LEFT channel and reference spikes
\  from its RIGHT channel.

\ Float arrays for interpolated counts:
spike&zero-array-len 8* constant interpolated-counts-array-len
fvariable unused8 create spike-loc-in-interpolated-counts  \ 20221228
 interpolated-counts-array-len allot
 spike-loc-in-interpolated-counts interpolated-counts-array-len erase
 spike-loc-in-interpolated-counts interpolated-counts-array-len +
 constant spikelocarrayend

\ : sliicountsput ( adr | fval -- )
\    dup spike-loc-in-interpolated-counts <  over spikelocarrayend >= or
\    if cr . ." IS AHEAD OR PAST END OF SLIICOUNTSARRAY! " . quit else f!
\    then ;

fvariable unuse08 create tone-neg-to-pos-interpolated-counts  \ 20221228
 spike&zero-array-len 8* allot  \ floats
 tone-neg-to-pos-interpolated-counts interpolated-counts-array-len erase
 tone-neg-to-pos-interpolated-counts interpolated-counts-array-len +
 constant tntparrayend

: tntpicountsput ( fval adr -- )
    dup  tone-neg-to-pos-interpolated-counts <  over tntparrayend >= or
    if cr . ." IS AHEAD OR PAST END OF TNTPICOUNTSARRAY! " . quit else f!
    then ;

\ Float signal buffers are set to start at locations in the long buffers
\ for the test function (included at the top of this source code)
\ instead of allocating separate buffers for rfforb.

\ The first part of the integer valued S16signal-buffer is reused to read
\ #batch-section-bytes bytes from the sound card for each batch buffer
\ section.

\ The 64-bit signal data for a batch section needs to be stored with
\ an extra #taps history samples from the sound card converted to floats.

\ NOTE: During SW development we maintain time correspondence for
\       original signal data, smoothed signal data, and FIR filtered
\       data in three buffers which get written out to three files.
\       Then by running audacity we can observe where the spikes and
\       zeros fall in the timeline using three tracks.

\ When doing FIR filtering the following pointers will be set for start
\ points where FIR filtering begins.
\ As we pass from one section to the next, these pointers will be advanced
\ by #batch-section-bytes.

\ These pointers store where in the signal and filtered
\ buffers FIR filtering starts for a section of a batch.
0 value S16-sig-batch-section-ptr  \ 20230217
0 value spike-sig-batch-section-ptr
0 value orig-sig-batch-section-ptr
0 value orig-sig-batch-section-FIRptr
0 value filtered-batch-section-FIRptr
0 value filtered-buffer-section-ptr  \ 20221127

orig-signal-buffer-len 8 / #batch-buf-sections *
  constant samples-per-batch    \ 20230218

: addFIRmemoryfloatbytes ( adr -- adr+#FIRhistory_bytes )
    #FIRfilter-history-float-data-bytes + ;
: addFIRmemorystereobytes ( adr -- adr+#FIRhistory_bytes )
    #FIRfilter-history-stereo-data-bytes + ;

0 value offset-to-batch-sec-data  \ 20230607

: do-offset-to-batch-sec-stereo-data ( adr -- adr+offset )  \ 20230218
    #batch-section-stereo-bytes-to-read-from-card-or-file
    batch-sec# * +  ;
: do-offset-to-batch-sec-float-data ( adr -- adr+offset )  \ 20230218
    #batch-section-float-bytes  batch-sec# * + ;

: init-batch-buffer-section-ptrs
  \ Where to write S16-sig data read from the stereo sound card
  \ or S16stereo prerecorded file  20230901
    S16signal-buffer
    addFIRmemorystereobytes \ 20240405
    do-offset-to-batch-sec-stereo-data
    to S16-sig-batch-section-ptr

  \ Where to write signal-buffer 64-bit data for the selected batch
  \ section (S16signal data converted to floats) in the signal buffer
  \ copy for the batch section
    signal-buffer
    addFIRmemoryfloatbytes
    do-offset-to-batch-sec-float-data
    to orig-sig-batch-section-ptr

  \ Where to write data in the spike buffer:
    spike-buffer
    do-offset-to-batch-sec-float-data
    to spike-sig-batch-section-ptr

  \ Where to write data in the FIR filtered signal buffer:
    filtered-buffer
    addFIRmemoryfloatbytes
    do-offset-to-batch-sec-float-data
    to filtered-buffer-section-ptr

  \ Where to start reading original signal data when starting to
  \ FIR filter a batch section:
    signal-buffer
    addFIRmemoryfloatbytes
    do-offset-to-batch-sec-float-data
    to orig-sig-batch-section-FIRptr
    \ We start there, but then the FIR filter backs up #taps-1 times
    \ accumulating smoothed signal float values multiplied by FIR coeefs,
    \ then it advances the FIR filtered data pointer
    \ #batch-section-samples times as it proceeds to filter
    \ #batch-section-samples-to-process samples up to the last one at
    \ smooth-sig-batch-section-ptr.

  \ Where to write FIR filtered data when starting to filter a batch
  \ section, also where to read data when finding tone zeros:
    filtered-buffer
    addFIRmemoryfloatbytes
    do-offset-to-batch-sec-float-data
    to filtered-batch-section-FIRptr
    \ The first #taps samples ahead of this pointer are not involved when
    \ computing an average bearing angle and quality factor. They are
    \ left blank so the FIR filtered file written out to the RPi "disk"
    \ would show where the batch section segments start and end when
    \ viewing by audacity.

    \ Null out the first part of filtered-buffer since we don't write
    \ there while FIR filtering.
  \  filtered-batch-section-FIRptr #FIRfilter-history-float-data-bytes
  \  erase
    ;
: ibbsp init-batch-buffer-section-ptrs ;
\ : dibbsp break: init-batch-buffer-section-ptrs ;

signal-buffer #batch-section-float-bytes #batch-buf-sections ( 20 ) * +
 constant last-section-sig-buf-history-start

: copy-sig-buf-tail-to-head \ 20230621
    last-section-sig-buf-history-start signal-buffer
    #FIRfilter-history-float-data-bytes cmove ;

0 value spike#

fvariable max-sig-slope  fvariable prev-sig-slope
fvariable max-sig-val  fvariable prev-sig-val  \ 20210818

\ fvariable max-Doppler-tone-slope
\  1 s>f  8 s>f f/ max-Doppler-tone-slope f!  \ 20221227

\ Now reading spike signal from the RIGHT stereo channel  20230321
fvariable min-spike-sig-slope
  1 s>f  8 s>f f/ min-spike-sig-slope f!  \ 20221227

  \ NOTE: The sound card vertical scale is volts for audacity and
  \ the time scale is in seconds. The max slope of y = sin(x)
  \ is simply 1 in units of a nondimensional y-axis and radians for
  \ the x-axis. For audacity the vertical scale is +-0.5 and
  \ saturation is at +1 volts coming into the sound card. For
  \ samples coming in at 48kbps the max audacity spike slope
  \ appears to be 1 when the spacing between sample arrows is
  \ visually comparable to spike heights, which makes sense. The
  \ spike 2-sample period at 48ksps is 41.6us and the Doppler tone
  \ period 1 / 16kHz = 625us is 15 times longer, so the slope of
  \ the RIR filtered sine wave appears to be about 1 near the time
  \ axis when the time scale is shrunk by a factor of about 16.
  \ To be safe, we set the max Doppler tone slope to 1/10, so the
  \ spikes will be unquestionably recognized.

\ There may have not been a spike occuring before the 1st zero found for
\ each batch section, in which case the 1st spike will be associated with
\ the 2nd zero, the 2nd spike with the 3rd zero, etc.


\ FALSE value see-spike&zero-data?

0 value spike-index
 \ index of spike# into the spike-loc-in-sig-buf array
0 value last-spike-index
 \ index of spike into the array at orig-sig-batch-section-ptr
0 value #section-spikes-found

variable orig-buf-loc   variable buf-loc-now
28 value min-spike-loc-gap

#batch-section-samples-to-process 30 /
dup constant section-max-zero+crossings
1- constant section-max-spikes
 \ limit for finding zero+ crossings spikes is 1 more than
 \  limit for finding spikes is this -1  20240308

 : pause   ."  pausing" key 27 = if quit then ;

: find-signal-spikes
    \ done for each section of a batch

    0 to spike#
    \ spike# will define where to store the spike's signal buffer index
    \ and will be incremented after using it to store an index.
    \ This will be 0,1,2,... but it will get incremented
    \ for displaying 1,2,3,... when debugging.

    -1 to spike-index
    \ Initally, to indicate that there was no spike yet.
    \ This will be an index into the array at orig-sig-batch-section-ptr.

    -1 to last-spike-index \ initially, so the first sample which
    \ appears to pass the spike test by large level jump will be
    \ accepted as a valid spike.

    0 to #section-spikes-found

    min-spike-sig-slope f@  max-sig-slope f!

    0 s>f  prev-sig-slope f!

    spike-sig-batch-section-ptr \ start at section pointer  20230215
   \ see-spike&zero-data?
   \ if cr ." adr to start looking for spikes:" dup . then
    ( ptr ) dup orig-buf-loc !  buf-loc-now !

    #batch-section-samples-to-process
    0 \ start at 1st sample
    \ The spike test below compares the present sample level to the
    \ previous sample level. We have no way to know if the first
    \ sample in a batch section is or is not a spike, because
    \ there was probably a significant time gap between batch section
    \ sound card readings due to phase angles processing and then
    \ writing out a phase angles sum to a text file, so the first sample
    \ of a batch section was captured after a time delay past the time
    \ of the last sample of the previous section.
    do
        buf-loc-now @ dup f@  signal-float-data-len - f@
        ( | fval prevfval ) f-
        ( | sig_level_of_this_sample_minus_prev_sample's )
        ( | fdeltaval ) fdup  max-sig-slope f@ f>
        \ Is there a large enough signal upward jump to qualify
        \ as a "spike" at this sample?
        ( flg | fdeltaval )
          \ Yeah, but wait-a-minute! There was maybe a "double spike"
          \ effect by there being an overlap of spiking appearing at
          \ adjacent indeces into the array spike-loc-in-sig-buf.
          \ Before adding the following test there were occasionally
          \ too many "spikes" resuting in overflowing of the
          \ predetermined array size for spikes.
        if
          \ may have found a new spike
         \ see-spike&zero-data?
         \ if
         \   cr ." We may have found a new spike at adr:"
         \   buf-loc-now @ .
         \ then
          \ get spike's index into the signal buffer
          ( | fdeltaval )  buf-loc-now @   orig-buf-loc @ -
          ( offset | fdeltaval ) 8 /
         \ see-spike&zero-data?
         \ if
         \   cr ." This adr less " orig-buf-loc @ .
         \   ." divided by 8 :" dup . cr
         \   ." may be index to spike-batch-section-ptr for a spike"
         \ then
          ( spike's_buffer_index | fdeltaval ) to spike-index
          spike-index last-spike-index 1+ >
          \ Is this spike not immediately after the previous spike?
          #section-spikes-found spike&zero-array-len <
          \ Is the spike loc array not yet full?
          ( flg1 flg2 | fdeltaval ) and
          spike-index last-spike-index - min-spike-loc-gap > and
          spike# section-max-spikes < and
          if
            \ yes, valid new spike
            ( | fdeltaval ) prev-sig-slope f!
            \ updated for comparing slope at next sample
           \ see-spike&zero-data?
           \ if
           \   cr ." We have a new spike at spike-loc index:"
           \   spike-index .
           \ then
            #section-spikes-found 1+ to #section-spikes-found
            spike-index to last-spike-index
            \ store spike's signal bufer index at spike-loc-index
            \ = spike# into the cell array spike-loc-in-sig-buf
            spike-index  spike# 4*
           \ ( index offset ) spike-loc-in-sig-buf + !
            ( index offset ) spike-loc-in-sig-buf +
            ( index array_adr ) slisbufput \ 20230702
            \ increment spike# after using it as an index into the
            \ spike-loc-in-sig-buf array
            spike# 1+ to spike#
            \ for displaying 1,2,.... when debugging
           \ see-spike&zero-data? if ." for spike#" spike# . then
            \ 20220430
          else
           \ see-spike&zero-data?
           \ if
           \   cr
           \   ." this is not a new spike or too many spikes were found"
           \   cr ." or it is just part of a 'double spike' effect"
           \ then
            ( | fdeltaval ) fdrop
          then
        else
          ( | fdeltaval ) fdrop
        then
        buf-loc-now @ signal-float-data-len + buf-loc-now !
    loop
 ;
: fss find-signal-spikes ;
\ : dfss break: find-signal-spikes ;

\ ====================================================================
\ Changed from quadratic polynomial fitting of expected signal values
\ during spikes to linearly proportional fitting of an interpolated
\ float "count" at the leading edge of a 20us rectangular spike 20230317

\ fvariable x0   fvariable x4  no longer used 20230611
 \ indeces before and after a spike cast as floats

\ fvariable y0   fvariable y4  no longer used 20230611
 \ float values of sound card samples before and after a spike

fvariable x1   fvariable x2   fvariable x3
 \ indeces into the sound card original signal buffer at
 \ three parts of a spike cast as floats

fvariable y1   fvariable y2   fvariable y3
 \ float values of sound card samples at 3 samples during a spike

\ fvariable l1   fvariable l2   fvariable l3  no longer used 20230611
 \ float values below the 3 spikes along a line through (x0,y0), (x4,y4)

fvariable f4.0e0   4 s>f f4.0e0 f!

\ FALSE value dbgisc?

: interpolate-spike-counts  \ revised 20230219
  \ Since this project began we used small USB sound cards that had only
  \ one input jack for a mono microphone. Christopher AI6KG remembered
  \ that he had a CM6206 sound card unit capable of recording in stereo,
  \ so this spike smoothing function was adapted to using spike data read
  \ by the stereo right side track concurrently with receiver audio from
  \ the left side track. Consequently, no smoothing out of spikes is
  \ required when interpolating an estimated count of the spike's
  \ leading edge "count" in a copy of the formerly combined spikes and
  \ received receiver audio.

  \ During the original SW development we wrote out the original signal,
  \ the smoothed signal, and the filtered batch section buffers to files
  \ for viewing via audacity to observe smoothing and FIR filtering
  \ performance.

  \ Using a stereo sound card we now read unadulerated receiver
  \ audio from the left stereo input and independent spike audio from
  \ the right input. For audacity evaluation, we additionally write out
  \ a 16-bit PCM stereo file.

  \ We still need to do the interpolation for the spike leading edge
  \ interpolated count as earlier in order to get higher precision for
  \ a pulse edge than just a nearest integer sound card sample number.    

  \ I assumed that sound card sampling windows are rectangular, so
  \ it makes more sense to estimate the "time" of the leading edge of the
  \ spike's 20us pulse by linear proportion based on the amount of overlap
  \ of its window with the sound card's 1/48kbps sampling windows. Those
  \ are theoretically slghtly over 21us; however, viewing audacity tracks
  \ from recorded files, I observed occasional pulse heights distributed
  \ over three concurrent sampling windows. I thought that the CM620
  \ sampling circuit gates a 1/48000 second capture into two ADC voltage
  \ holders at the LEFT and RIGHT channels and then it digitizes and
  \ stores those voltage values while it grabs the next sample levels.

  \ Apparently there is some charge and discharge time involved because
  \ the 20ms sync pulses appear to affect as many as 3 consecutive CM6202
  \ sampling windows.
   
  \ NOTE: I removed the capacitor I had in my RPi "hat" in the spike
  \ signal path between GPIO pin 25 and a pair of resistors for mixing
  \ receiver and spike audio going into the mono sound card used earlier.
  \ The decaying signal between spikes at the RIGHT channel input seems
  \ to be unavoidable. It undoubtedly is due to internal DC isolating
  \ capacitors in series with the LEFT and RIGHT channel inputs.
  
  \ BTW two resistors were added in the spike signal path on the revised
  \ RPi3B hat which act as a voltage divider so as not to over drive the
  \ RIGHT channel input.

  #section-spikes-found
  dup  spike&zero-array-len > \ 29221121
  if
    cr ." batch#" batch# . ." batch-sec#" batch-sec# .
    cr ." #section-spikes-found:" . ." EXCEEDS ARRAY SIZES!" quit
  then

  dup 0=
  if
   drop \ 20221125
  else
    ( #section-spikes-found ) 0
    do
      i 4* spike-loc-in-sig-buf + @
      \ index into the spike-sig-batch-section-ptr array for i-th spike

      \ The indeces in the spike-loc-in-sig-buf array are 32-bit integers
      \ whose values are sound card sample numbers 0,1,2... counting from
      \ the start of data for the current batch section.

      \ Cast spike buffer indeces as floats to be used for
      \ interpolation:
 \   ( index_to_spikebuf_loc ) dup 2 - s>f x4 f! no longer used 20230321
 \   ( index_to_spikebuf_loc ) dup 1-  s>f x0 f!
      ( index_to_spikebuf_loc ) dup     s>f x1 f!
      ( index_to_spikebuf_loc ) dup 1+  s>f x2 f!
      ( index_to_spikebuf_loc ) dup 2 + s>f x3 f!

      ( 1st_spike_loc | -- )

    \ Earlier when viewing recorded receiver data mixed with spikes using
    \ audacity, it was observed that only rarely does a spike overlap a
    \ 3rd sound card sampling window. Most spikes appeared spread over
    \ two sound card sampling periods resuting in two "half spikes" whose
    \ ampitudes added up to the height of an occasionally seen "single
    \ spike".

    \ By mono sound there appeared additional "spike remnants" of very low
    \ amplitude just ahead of the "first half" spike and/or one just after
    \ the "second half", so to be safe we used 3, 2 samples back of "the
    \ spike" and one after its "second half" to do linear "baseline"
    \ interpolation for signal values expected without a spike and then we
    \ we did quadratic polynomial interpolation to estimate a spike
    \ leading edge "time".

    \ Now that a clean spike signal is isolated from receiver audio in the
    \ RIGHT stereo channel, it appears that a 3rd spike "remnant" is quite
    \ noticeable ahead or after a spike, so the algorithm has been changed
    \ to use the RIGHT channel value just before the set of three spikes
    \ rising above a specified threshold then two following elevated
    \ signal values from the RIGHT stereo channel.

      \ Store signal float values in float variables used to interpolate:
      ( 1st_spike_part's_count_loc )
      \ This is an index into an array at spike-sig-batch-section-ptr.
      \ The value there is a sample count from the start of the current
      \ batch section. We multiply that by 8 to reach the float value
      \ of the 1st of 3 consecutive spike parts:
      ( index ) 8* spike-sig-batch-section-ptr +
     \ ( spikesigbufadr ) dup 16 -  f@ y4 f!
     \ ( spikesigbufadr ) dup 8 -   f@ y0 f! no longer used  20230321
      ( spikesigbufadr ) dup       f@ y1 f!
      ( spikesigbufadr ) dup 8 +   f@ y2 f!
      ( spikesigbufadr )     16 +  f@ y3 f!
      ( -- | -- )
      \ Now compute a proprtionally interpolated "count" value for the
      \ spike event based on the observation that the spikes appear on
      \ an oscilloscope as almost perfect flat top pulses 1/48000s wide
      \ whereas the three spike levels appear in a stretched time axis
      \ audacity view as vertical bars having a constant sum of lengths
      \ above a gradually decaying baseline.

      \ Imagine a straight line between X-Y plane points (x0,y0), (x4,y4).
      \ Then imagine that a charge was growing in a capacitor inside the
      \ CM6206 sound card theoretically during a 20us spike interval, but
      \ that didn't fully charge the capacitor within one 1/48000th sec
      \ sound card sampling time interval. It is reasonable to assume
      \ that the sound card sampling circuit measured 3 values above the
      \ gradually decenting baseline, which proportinally represent an
      \ amount of time each of 3 sampling windows overlapped a stretched
      \ out pulse effect.

      \ Previously when using a mono card, spikes appeared spread out only
      \ over at most two sound card sampling periods but now the stereo
      \ card seems to pick up the 20us pulses during three consecutive
      \ samples.

      \ Tentatively, we assume that the voltage built up on a capacitor
      \ during each of 3 consecutive sample counts is proportional to each
      \ sampling interval's overlap with a voltage presented to an ADC
      \ during that interval.

      \ The following Cartesian geometry calculations arrive at an
      \ interpolated pulse center "time" of a stretched out pulse effect
      \ resulting from an actual 20us pulse presented at the sound card
      \ RIGHT channel input. This model assumes that the sound card
      \ voltage sensing circuit latches a value during a RIGHT channel
      \ reading cycle and holds it for some as yet undefined time.

      \ Imagine a set of 3 quadrangles above the line in the X-Y plane
      \ above line segment between the points (x0,y0) and (x4,y4), each
      \ of which has a height equal to the amplitude of the corresponding
      \ spike signal amplitude measured by the sound card. Then think of
      \ those 3 quadrangles as having a "weight", so we want to calculate
      \ where on the X axis is their "center of gravity". That will give
      \ us a reasonable estimate of a "center time of influence" of the
      \ sync pulse.

     \ y0 f@   y4 f@  fover f- f4.0e0 f@ f/
     \ dbgisc? if cr ." slope:" fdup f. then
     \ ( | y0 baseline_slope ) fover fover f+ fdup l1 f!
     \ ( | y0 baseline_slope y0+baseline_slope ) fover f+ fdup l2 f!
     \ ( | y0 baseline_slope y0+2*baseline_slope ) f+ l3 f!
     \ ( | y0 ) fdrop

     \ y1 f@ l1 f@ f-  x1 f@ f*
     \ y2 f@ l2 f@ f-  x2 f@ f*  f+
     \ y3 f@ l3 f@ f-  x3 f@ f*  f+
      y1 f@  x1 f@ f*  \ 20230321
      y2 f@  x2 f@ f*  f+
     \ y3 f@  x3 f@ f*  f+
      ( | numerator )
     \ dbgisc? if cr ." numerator:" fdup f. then

     \ y1 f@ l1 f@ f-
     \ y2 f@ l2 f@ f-  f+
     \ y3 f@ l3 f@ f-  f+
      y1 f@  y2 f@  f+ \ y3 f@  f+
      ( | numerator denominator )
     \ dbgisc? if cr ." denominator:" fdup f. then

     \ dbgisc?
     \ if
     \  cr ." x:" x1 f@ f. x2 f@ f. x3 f@ f.
     \  cr ." y:" y1 f@ f. y2 f@ f. y3 f@ f.
     \ \ cr ." l:" l1 f@ f. l2 f@ f. l3 f@ f.
     \ then
      ( | numer denom ) f/
     \ dbgisc?
     \ if
     \  cr ." interpolated spike count:" fdup f. f.s pause
     \ then
      ( | numer denom )
      spike-loc-in-interpolated-counts i 8* +
      ( spikelocarrayadr | ratio ) f!
     \ ( spikelocarrayadr | ratio ) sliicountsput \ 20230626
      ( -- )
    loop
  then ;
\ : isc  interpolate-spike-counts ; \ 20230310

: view-all-spike-counts
    cr #section-spikes-found . ." total spike counts found:"
    spike-loc-in-sig-buf   #section-spikes-found 0 >
    if
      #section-spikes-found 0
      do
        i 16 mod 0= if cr then  dup @ .  4 +
      loop
    else
      ." NO SPIKES FOUND"
    then
    ( adr ) drop
  ;
: vasc view-all-spike-counts ;


fvariable prev_tone_val

0 value tone_buf_index
  \ byte offset into the array of floats at filtered-batch-section-ptr

0 value next_spike_index
\ index into the array of floats at orig-sig-batch-section-ptr

0 value #section_zero+crossings

TRUE value not_found_a_zero+?

\ FALSE value dbg-fdtz?

\ : chk ( n -- )
\    dbg-fdtz?
\    if
\       cr . ." chk "  .s  key 27 =
\       if quit then
\    else
\      ( n ) drop
\    then
 \ ;

fvariable this_tone_val  \  20221021

: interpolate-tone-count ( index -- )
    ( index ) dup s>f this_tone_val f@ f*
    ( index | this_tone_val*this_index )
    ( index | this_tone*index ) 1- s>f  prev_tone_val f@ fnegate f*
    ( | this_tone_val*[this_index-1] prev_tone_val*prev_index ) f+
    ( | numerator ) this_tone_val f@  prev_tone_val f@ fnegate f+
    ( | numerator denominator ) f/
    \ interpolated "sample count" float value
    \ store it in the neg-to-pos crossing incidents array
    #section_zero+crossings \ index into the interpolated counts array
    ( counts_array_index | float_ratio )
    8* tone-neg-to-pos-interpolated-counts +
    ( tntpicounts_adr | fval ) tntpicountsput ;

: check-if-tone-crossed-neg-to-pos
    tone_buf_index
    \ We start looking at filtered-batch-section-FIRptr + tone_buf_index

    begin
       ( tone_buf_index )
       \ Check if the tone at tone_buf_index is a zero+ crossing. If
       \ yes, store tone_buf_index in the neg-to-pos-loc-in-FIR-buf
       \ index array.

       \ 20221017
       \ We now also store a linearly interpolated float number
       \ representing an interpolated count for the pos to neg zero
       \ crossing event, based proportionately on the negative FIR
       \ filtered Doppler tone value and the positive or zero current
       \ tone value.
       \ The "time" offset from this to the "time" of the previous spike
       \ will be later scaled to a Doppler tone phase angle in degrees.

       ( index ) dup 8* filtered-batch-section-FIRptr + f@
       ( index fval ) fdup this_tone_val f!
      \ dbg-fdtz? if cr ." toneval:" fdup f. then
       ( index fval )  dup 1- 8* filtered-batch-section-FIRptr + f@
       fdup prev_tone_val f!
      \ dbg-fdtz? if cr ." prevtone:"  fdup f. then
       ( index | fval prevfval ) f0< \ 20240316
       ( index flg | fval ) f0>= and
       ( index flg )
       \ index = new tone's index to the array at
       \ filtered-batch-section-FIRptr
       #section_zero+crossings section-max-zero+crossings < and \ 20240308
       if
         \ dbg-fdtz?
         \ if cr ." The tone crossed from neg to pos or zero value." then
          FALSE to not_found_a_zero+?

         \ dbg-fdtz?
         \ if
         \   cr ." new zero+ crossing index " dup .
         \   ( index=new_tone's_loc_array_index )
         \   cr ." is stored at neg-to-pos-loc-in-FIR-buf index:"
         \   #section_zero+crossings .
         \   2 chk
         \ then

          ( index ) dup interpolate-tone-count
          ( index ) dup
          \ Advance the count of neg to pos zero crossings:
          #section_zero+crossings dup 1+ to #section_zero+crossings

          ( index index #zero+_crossings ) 4* \ 20230705
          neg-to-pos-loc-in-FIR-buf + !
          \ stored filtered buffer byte offset value of this neg-to-pos
          \ event in the neg-to-pos crossings list slot for this event
       then
       ( index )
       not_found_a_zero+?
       ( index flg ) #section_zero+crossings spike&zero-array-len < and
       ( index flg ) next_spike_index tone_buf_index > and
    while
       ( index ) 1+  dup to tone_buf_index

      \ dbg-fdtz?
      \ if
      \    cr ." go look at next FIR filtered tone at next tone index:"
      \    dup . 3 chk
      \ then
    repeat
    ( tone_buf_index ) drop
    \ NOTE: This was the original index when entering the above loop, but
    \  tone_buf_index got advanced during the search.
    ;

: getToneOffsetRangeToSearch
      spike# 4* spike-loc-in-sig-buf + @
      ( spike_index ) \ #floats from orig-sig-batch-section-ptr
     \ dbg-fdtz?
     \ if
     \    cr ." Looking for a zero at or after spike#" spike# 1+ .
     \    ."  at sigbuf index:" dup . -3 chk
     \ then

      \ To get the spike value there we would add this index times 8 to
      \ orig-sig-batch-section-ptr and fetch the signal value, but here
      \ we just need this index to start a search for Doppler tone neg to
      \ pos crossings starting at the same index into the float array at
      \ filtered-batch-section-FIRptr as the spike's index into the
      \ original unsmoothed signal buffer. Why? Because we know that the
      \ spike was caused by Ant1 ON after Ant4 OFF and the FIR filtered
      \ sine wave must have one and only one positive going zero crossing
      \ before the next spike happens. Why one and only one? Because the
      \ FIR filter does such a good job of suppressing audio outside of a
      \ narrow pass band, and interpolate-spike-counts does a good
      \ suppression of spike residues, so we can safely assume there are
      \ no other FIR filtered signal up and down jumps anywhere within a
      \ Doppler tone cycle.
    \ NOTE: The last comment phrase no longer applies! We now read
    \ totally isolated spikes in the right stereo sound card channel,
    \ so there is no way for slight signal jumps to cause more than
    \ one zero+ crossing between spikes.

    \ Nevertheless, as the Doppler tone phase changes it is possible
    \ that a zero+ crossing can be very soon after a spike and the gap
    \ between zero+ crossings can be swiftly shortening, e.g., when
    \ the signal looks like random noise, causing the next zero+ crossing
    \ to be just ahead of the next spike. In that case we need to keep
    \ looking for a zero+ crossing a small number of sound card counts
    \ (forward-step) before the next spike.   20231121

      ( spike_buf_float_index )
      \ index is number of floats past the start of FIR filtered buffer
      \ pointer for this batch section

     dup 0 >
     if
          \ This spike is not at the batch-section start, so we begin
          \ looking at this index in the FIR filtered buffer.
          ( spike_buf_index ) dup to tone_buf_index
          ( tone_buf_index )  1-
         \ dbg-fdtz?  if ." prev tone index " dup . -1 chk then
          ( indx-1 ) 8* filtered-batch-section-FIRptr + f@
          ( -- | fval ) prev_tone_val f!
          spike# 1+ 4* spike-loc-in-sig-buf + @
           \ next spike's orig sig buf index (number of floats) relative
           \ to orig-sig-batch-section-ptr
          ( spike_index+1 ) to next_spike_index
  \    else

     \ No need to do this -- the first spike we can use will be after
     \    the 10 spikes occuring during the initial history used by the
     \    FIR filter to back track for its required job.   20221119

     \    \ We cannot use the spike as the first tone to be examined
     \    \ because ahead of the start of the batch section we didn't FIR
     \    \ filter any smoothed tones. So we fake a previous tone value,
     \    \ making the "previous" tone be the same value as the next
     \    \ tone, and we skip to the next tone to start looking for a
     \    \ zero+ crossing.
         \ dbg-fdtz? if cr ." no prev tone available" -2 chk then
     \     ( spike_buf_index ) dup filtered-batch-section-FIRptr + f@
     \     ( spike_index | fval )   prev_tone_val f!
     \     ( spike_index ) 1+ spike-loc-in-sig-buf + @ to tone_buf_index
     \     spike# 2 + 4* spike-loc-in-sig-buf + @ to next_spike_index
      then
    ;

: find-Doppler-tone-neg-to-pos-crossings
  0 to #section_zero+crossings

  #section-spikes-found dup  0>
  ( n flg )
  if
    \ one or more spikes were found in this section, and the spike and
    \ zero location arrays are not already full
    0 ( #section-spikes-found initial_index )
    batch-sec# 0=
    if
     \ ( #section-spikes-found 0 ) 10 -   10    \ 20221119
     \  ( #zero-crossings 0) drop #FIR-history-ant-rot-cycles -
     \  #FIR-history-ant-rot-cycles
      \ Skip past the first FIR history spikes, because the FIR filter
      \ starts getting its signal input from the signal buffer past the
      \ initial history. It also reads FIR history samples back of each
      \ input signal to do the filtering.
      \ The filtered-batch-section-FIRptr is set to look for zero
      \ crossings in the signal buffer after FIR filter history.
    then
    ( #actual-spikes-to-use starting-index ) \ 20230312
    do
        i to spike#  getToneOffsetRangeToSearch \ sets tone_buf_index
        TRUE to not_found_a_zero+?
        \ Loop on tones starting at or just after this spike, but don't
        \ look beyond the next spike.
        check-if-tone-crossed-neg-to-pos
        \ started looking at tone_buf_index set by
        \ getToneOffsetRangeToSearch, then advanced tone_buf_index
     \ dbg-fdtz?
     \ if
     \   cr ." proceed to find a zero+ crossing for the next spike" 4 chk
     \ then
    loop
   \ dbg-fdtz? if cr ." end of loop on #section-spikes-found" then

  else
    ( #section-spikes-found=0 ) drop   \ 20221125
   \ cr ." NO SPIKES WERE FOUND in this batch section, "
   \ cr ." or the spike and zero location arrays are already full"
   \ cr ." so you shouldn't be looking for any more zero crossings!"
   \ quit
  then
  ;

: fdtz
   find-Doppler-tone-neg-to-pos-crossings
   ;
\ : dfdtz break: fdtz ;

: show-zero-counts ( adr #zeros_to_see 1st_index_to_use )
   do
      i 16 mod 0= if cr then
      ( adr )  dup @ . 4 +
   loop ( adr ) drop
 ;
  
: view-zero-counts  \ 20230312
    cr   #section_zero+crossings 0 >
    if
      cr #section_zero+crossings . ." neg to pos crossing sample counts:"
      neg-to-pos-loc-in-FIR-buf   #section_zero+crossings 0
      ( adr #zero_crossings  1st_index_to_use=0 )
      batch-sec# 0=
      if
         #section_zero+crossings #FIR-history-ant-rot-cycles >
         if
           \ We skip the first FIR history spikes for the first section
           \  20221121
           \ swap #FIR-history-ant-rot-cycles - swap
            ( adr #zeros_to_see 1st_index_to_use ) show-zero-counts
         else
            cr ." Too few zero crossings after FIR history!"
            ( adr #zeros_to_see 1st_index_to_use ) 2drop drop
         then
      else
         ( adr #zeros_to_see 1st_index_to_use=0 ) show-zero-counts
      then
    else
      cr ." NO ZERO CROSSINGS FOUND"
    then
 ;
: vzc view-zero-counts ;

: show-interpolated-counts ( adr #zeros_to_see 1st_index_to_use )
   do
      i 16 mod 0= if cr then
      ( adr )  dup f@ f. 8 +
   loop ( adr ) drop
 ;

: view-interpolated-zero-counts
    #section_zero+crossings 0 >
    if
      cr #section_zero+crossings .
      ." neg to pos crossing interpolated counts:"
      tone-neg-to-pos-interpolated-counts   #section_zero+crossings 0
     \ batch-sec# 0=
     \ ( adr #zero_crossings  1st_index_to_use=0 )
     \ if
     \    #section_zero+crossings #FIR-history-ant-rot-cycles >
     \    if
     \      \ We skip the first FIR history spikes for the first section
     \      \  20221121
     \      \ swap #FIR-history-ant-rot-cycles - swap
     \      ( adr #zeros_to_see 1st_index_to_use )
     \      show-interpolated-counts
     \    else
     \       cr ." Too few zero crossings after FIR history!"
     \       ( adr #zeros_to_see 1st_index_to_use ) 2drop drop
     \    then
     \ else
         ( adr #zeros 1st_index=0 ) show-interpolated-counts
     \ then
    else
      cr ." NO ZERO CROSSINGS FOUND"
    then
 ;
: vizc view-interpolated-zero-counts ;

: show-spike-counts ( adr #spikes 1st_index_to_use )
   do
      i 16 mod 0= if cr then
      ( adr )  dup @ . 4 +
   loop ( adr ) drop
 ;

: view-spikes&zeros
    \ Bearing angles are clockwise from true north
   \ batch-sec# 0=
   \ if
   \   cr ." We skip past the first " #FIR-history-ant-rot-cycles .
   \   ." spikes in the FIR history"
   \   cr ." when computing spike count gaps from a spike to the next"
   \   cr ." neg to pos zero crossing"
   \ then

    #section-spikes-found 0 >
    if
      spike-loc-in-sig-buf   #section-spikes-found 0
     \ ( adr count initial_index=0 )  batch-sec# 0=
     \ if
     \  \ We skip the first FIR history spikes for the first section
     \  ( adr #spikes 0) swap #FIR-history-ant-rot-cycles - swap
      \ 20230312
     \  rot #FIR-history-ant-rot-cycles 4* + rot rot
     \ then

      cr over . ." usable spikes found:" cr
      ( adr #spikes_to_see 1st_index_to_use ) show-spike-counts

      cr #section-spikes-found . ." interpolated spike counts:" cr
      spike-loc-in-interpolated-counts   #section-spikes-found 0
     \ ( adr count initial_index=0 )  batch-sec# 0=
     \ if
     \  \ We skip the first FIR history spikes for the first section
     \  ( adr #spikes 0) swap #FIR-history-ant-rot-cycles - swap
      \ 20230312
     \  rot #FIR-history-ant-rot-cycles 4* + rot rot
     \ then

      ( adr #spikes_to_see 1st_index_to_use )
      do
        i
       \ batch-sec# 0= 
       \ if  #FIR-history-ant-rot-cycles - then
       \ 16 mod 0= if cr then  dup f@ f.  float +
       \ The GFTP lacks Forth's float constant and complains when we
       \ redefine 'float' which is already has in its lexicon.
        16 mod 0= if cr then  dup f@ f. 8 +
      loop ( adr ) drop
    else
      ." NO SPIKES FOUND"
    then

    vzc  vizc
    ;
: vsz view-spikes&zeros ;
: dvsz break: view-spikes&zeros ;

FALSE value show-phase-angles?

\ fvariable fsamples/tone-cycle
\ #samples/tone-cycle s>f fsamples/tone-cycle f! \

\ Cartesian representation of a complex number   20210723
fvariable unused9 create phase-angle-x
  spike&zero-array-len 8* allot
fvariable unuse10 create phase-angle-y
  spike&zero-array-len 8* allot
\ Why do this? Because to get the average direction you add unit vectors,
\ so you average their Cartesian coordinates and compute the angle.
\ Also the magnitude of the vector sum gives you a measure of the quality
\ of the bearing estimate directly.
\ When you add N unit vectors all of the same direction
\ you get magnitude N, and when their angles are randomly scattered
\ you get a low vector sum magnitude, which becomes zero in the limit
\ when the vector ends are evenly distributed around a circle.

: fpi 1 s>f fatan ( pi/4 ) 4 s>f f* ;  \ 20220130
: f2pi 1 s>f fatan ( pi/4 ) 8 s>f f* ; \ 20240405
: radians>degrees ( | fradians -- | fdegrees ) 180 s>f f* fpi f/ ;

: show-phase-angle-x&y-values
    \ Bearing angles are clockwise from true north   \ 20221213
    cr ." phase angle x and yscaled to +-9999:"
    #section_zero+crossings 0 >
    if
      #section_zero+crossings  #section-spikes-found min  0
      do
        i 16 mod 0= if cr then  i 8*
        ( i*8 ) phase-angle-x + f@ 9999 s>f f* f>s .
      loop
      #section_zero+crossings  #section-spikes-found min  0
      do
        i 16 mod 0= if cr then  i 8*
        ( i*8 ) phase-angle-y + f@ 9999 s>f f* f>s .
      loop
    else
        cr ." No zeros found!"
    then
    ;
: spaxy show-phase-angle-x&y-values ;

: kfsqrt  flog 2 s>f f/ f10 fswap f** ; \ no fsqrt in transpiler  20221215

\ The GFTP can't handle gforth's floating point constant representation
\ and it lacks fconstant, so we need to use fvariable.
fvariable f30    30 s>f f30  f!   \ 20220615
fvariable f45    45 s>f f45  f!   \ 20220613
fvariable f90    90 s>f f90  f!   \ moved up here  20220613
fvariable f100  100 s>f f100 f!
fvariable f180  180 s>f f180 f!   \ moved up here  20220602
fvariable f270  270 s>f f270 f!   \ 20220613
fvariable f360  360 s>f f360 f!   \ 20220613

fvariable sinval  fvariable cosval   \ 20220613

\ NOTE: Bearing angles are measured clockwise from tue north.
\ So a unit length vector with angle 0 has x = 0, y = 1.    20221213

\ The GFTP lacks f0>, etc, fatan2    20220614
\ kfatan2degrees is my version of fatan2 in gforth
\ which is not in the GFTP.

: kfatan2 ( | fx fy -- | arctan[fx/fy] ) \ angle in radians  20221213
    ( | fx fy ) fover sinval f! fdup cosval f!
    fswap fabs fswap fabs f/  fatan
    sinval f@ f0> cosval f@ f0< and
    if ( ." ><" ) fpi fswap f- then
    sinval f@ f0< cosval f@ f0< and
    if ( ." <<" ) fpi f- then
    sinval f@ f0< cosval f@ f0> and
    if ( ." <>" ) fnegate then
    ;

\ Bearing angles are clockwise from the y-axis thought of as true north
\ We want to send values 0.0e0 through 359.9e0 to stdout as 4-digit
\ text scaled up by 10 so as to have one decimal point resolution.

\ We send Doppler phase angles to stdout in degrees as 4-digit ASCII text
\ 0000 to 3599

 : test-kfatan2   \ repaired 20240326
    \ We deal with clockwise bearing angles from tue north, so a vector
    \ (x=0,y=1) has angle 0 and (x=1,y=0) has angle 90 degrees.
    \ The traditional fatan function in all the Forth's is for angles
    \ going counter clockwise from the X axis.
    cr ." theta  cos(theta)  sin(theta) fatan(x y) kfatan2 fatan2" cr
    #samples/tone-cycle ( 30 ) 0
    do
        i 12 * dup . s>f \ float angle degrees = 0,12,24,...348
        ( | i*12 ) f2pi f* f360 f@ f/ \ 2pi*(i*12)/360 = radians 
         \ fdup fsin  fswap fcos
          fdup fcos  fswap fsin \ 20240326
        ( | x-val y-val ) fover f. fdup f.
        ( | x-val y-val ) fover fover  fatan f.
        ( | x-val y-val ) fover fover  kfatan2 f.
        ( | x-val y-val )  fatan2 f. cr \ 20221215
    loop ;
 : tfut  test-kfatan2 ;
\ : dtfut break: test-kfatan2 ;

: show-vector-angles
    cr ." phase vector angles * 10 (0 to 3599):"
    #section_zero+crossings 0 >
    if
      #section_zero+crossings 0
      do
        i 16 mod 0= if cr then
        \ Bearing angles are clockwise from true north
        i 8* dup phase-angle-x + f@
        ( i*8 ) phase-angle-y + f@  kfatan2
        \ fatan2 is not in the transpiler
        radians>degrees ( -180 to 180 deg ) fdup f0.0e0 f<
        if f360 f@ fswap f+ then  f10 f* f>s .
     loop
    else
        cr ." No zeros found!"
    then ;
: sva  show-vector-angles ;

0 value bad-vector
fvariable f1000   1000 s>f f1000 f!
 FALSE value chkvecsum?

: check-vector-magnitudes  \ 20240306
    0 to bad-vector
    #section_zero+crossings 0 >
    if
      chkvecsum?
      if
        cr #section_zero+crossings . ." phase vector magnitudes * 1000:"
      then
      #section_zero+crossings 0
      do
        chkvecsum? if i 16 mod 0= if cr then then
        i 8* dup phase-angle-x + f@ fdup f*
        ( i*8 ) phase-angle-y + f@ fdup f* f+ kfsqrt f1000 f@ f*
        f>s chkvecsum? if dup . then
        990 <
        if
         chkvecsum? if ." BAD M" then 1 to bad-vector
        then
     loop
    else
      chkvecsum? if cr ." No zero+ found!" then
    then ;
: cvm  check-vector-magnitudes ;

0 value bad-spike

: check-all-spike-counts
    0 to bad-spike
    spike-loc-in-sig-buf   #section-spikes-found 0 >
    if
      chkvecsum?
      if
        cr ." Checking " #section-spikes-found .
        ." spikes for null counts:"
      then
      #section-spikes-found 0
      do
        chkvecsum?
        if
          i 16 mod 0= if cr then
          dup @ .
        then
        dup @ 0=
        if
          chkvecsum? if ." BAD S" then
          #section-spikes-found  1- to #section-spikes-found
          TRUE to bad-spike
        then
        4 +
      loop
    else
      chkvecsum? if ." NO SPIKES FOUND!" then
    then
    ( adr ) drop
  ;
: casc check-all-spike-counts ;

0 value bad-zero+

: check-zero+counts
   0 to bad-zero+
   chkvecsum? if cr ." Check for null zero crossing counts" then
   #section_zero+crossings dup section-max-zero+crossings <=
   swap 0 > and \ 20240308
   if
    neg-to-pos-loc-in-FIR-buf  #section_zero+crossings 0
    do
      chkvecsum? if i 16 mod 0= if cr then then
      ( adr )  dup @ chkvecsum? if dup . then
      0=
      if
        #section_zero+crossings 1- to #section_zero+crossings
        TRUE to bad-zero+
        chkvecsum? if ." BAD Z " then
      then 
      4 +
    loop ( adr ) drop
   else
    chkvecsum? if cr ." TOO MANY ZERO+CROSSINGS" then
   then
 ;
: czc check-zero+counts ;
: dczc break: check-zero+counts ;

0 value cyc#offset
 \ this will be the offset into the arrays of Doppler tone zero crossings
 \ and spikes as the vectors are summed

fvariable sec-avg-vec-x   fvariable sec-avg-vec-y

\ 20221018
\ NOTE: Before changing to estimating interpolated counts as floats,
\ the resolution of the phase angle obtained by summing
\ the x and y coordinates was +-(1/2)2pi/30 radians.

\ So that is about +-(360/3.14)/30 = +-3.82 deg, and enough angle
\ representing digits in a text formatted integer was planned to send
\ to Bearings_capture for later adapting it to take
\ advantage of higher resolution than it was getting from a DDF-1,
\ i.e., +-(1/2)(360/16) = +-11.25 deg.

\ Instead of sending one nibble for 1 of 16 DDF-1 LED's to a captured
\ bearings file, we were sending 4 ASCII characters for a bearing angle
\ degrees times 10 from 0 to 3599, a bearing quality factor in ASCII
\ text in the range 0 to 999 terminated by an LF, then a max Doppler
\ tone peak value 9 to 999.   \ 20220620

\ For testing we follow the bearing data by the Linux utime-msecs in
\ a text string at the time of each bearing capture.  \ 20220620

\ 20221018   For now, we continue the same precision for angles.
\  After checking out performance of the sound card counts interpolation
\  it may be found that bearings can be more precisely measured.

 TRUE value keep-looking?

0 value max_spike_count
0 value showvecdata?
0 value showbadvector?
0 value showvecangles?

: get-phase-angles-vector-sum
   \ Now that we have AI6KG's improved antenna switching Task1 with
   \ no longer big jitter delays occasionally delaying a neg to pos zero
   \ crossing after a spike till after the next spike occurs, we no longer
   \ need to search for the spike just before a zero crossing. Therefore
   \ we loop through the lists of zero crossings found.

   \ fill out the phase-angle-x and phase-angle-y arrays and sum them
   \ in sec-avg-vec-x and sec-avg-vec-y

   \ Init sec avg vector coordinates for the vector sum.
    0 s>f fdup sec-avg-vec-x f!  sec-avg-vec-y f!

    0 to cyc#offset \ offset to n-th zero crossing slots at the
                    \ phase-angle-y & phase-angle-y arrays
    chkvecsum?
    if cr .s cr ." Check for null spike and zero counts" then
    check-all-spike-counts  check-zero+counts \ 20240307

    #section_zero+crossings 0 >
    ( #zero+crossings flg )
    #section_zero+crossings spike&zero-array-len <= and \ 20230314
    if
     #section_zero+crossings 0
     ( loop_count=#zero+crossings start_index=spike#_to_use_first=0 )

     showvecdata?
     if
       cr ." start gpavs, #zero+crossings found:" over . \ 20230314
     then

   \  batch-sec# 0=
   \  if
   \    drop  #FIR-history-ant-rot-cycles swap over - swap
   \    ( reduced_loop_count new_start_index )
   \    chkvecsum?
   \    if
   \      cr ." In the 1st batch section we start looking at spike#"
   \      dup 1+ . ." past the first FIR fliter history spikes"
   \      cr ." when looking for the next neg to pos zero crossing"
   \    then
   \    ( reduced_loop_count init_index=#FIR-his-ant-rot-cycs )
   \  then
    \ now we process the 1st section the same way as others 20230611

     TRUE to keep-looking?
     \ assume we will find a zero+ after spike#

     ( loop_count=#zero+crossings start_index=spike#_to_use_first )
     to spike#  to max_spike_count

     showvecdata?
     if
       cr ." spike#  degrees   angle-x   sum-x   angle-y   sum-y"
     then

     begin
       spike# 8*
       \ index offset into array holding the interpolated "count" for this
       \ spike 20230310
       spike-loc-in-interpolated-counts + f@
       \ interpolated count for this spike

\       chkvecsum?
\       if
\         cr ." interpolated count for spike#" spike# 1+ .
\       then

       spike# 1+   #section_zero+crossings <=
       if
        \ Begin looking for a zero crossing whose interpolated count
        \ found by find-Doppler-tone-neg-to-pos-crossings is at or after
        \ this spike.

        spike# 8*
        \ batch-sec# 0=
        \ if #FIR-history-ant-rot-cycles 8* - then 20230312
        \ Back off by #FIR-history-ant-rot-cycles
        \ if batch-sec# = 0, because zero+ crossings were searched
        \ for and logged only after the first #FIR-history-ant-rot-cycles
        \ spikes for the first section of a batch.
        \ Now we no longer do this.  20240119
        
        ( array_offset_of_zero_to_be_checked | spike_interp_count )
       \ chkvecsum?
       \ if
       \   cr ." Begin looking for zero+ at spike#" spike# 1+ .
       \   ."  interpolated count:" fdup f. \ .s f.s
       \ then

        begin
         ( array_offset_of_zero_to_be_checked | spike_interp_count )
         dup spike&zero-array-len 8* >
         if
         \ chkvecsum?
         \ if
         \  dup cr ." zero+ loc array offset:" .
         \  ." is past the end of the array for interpolated zero+ counts"
         \  fdrop drop quit
         \ then
          FALSE dup to keep-looking?
          ( zero_ofs flg | spike_interp_count ) f0.0e0
          ( zero_ofs flg | spike_interp_count zero_interp_count )
         else
          \ Check if zero_interp_count is behind spike_interp_count,
          \ which means we have to keep looking for a zero+ at or
          \ after spike_interp_count.
          dup tone-neg-to-pos-interpolated-counts + f@
\          chkvecsum? if cr ." zero+ interp_count:" fdup f. then
          ( zero_ofs | spike_interp_count zero_interp_count )
          fover fover f-  f1000 f@ f* f>d d0>
          ( zero_ofs flg | spike_interp_count zero_interp_count )
          \ zero+ is after the spike, so keep looking
         then
         keep-looking? and
        while
         \ The zero crossing is behind this spike, so we need to
         \ advance the zero+ index offset to find the first zero+
         \ crossing that came at or after this spike.
         ( zero_loc_array_offset | spike_count zero_count )
         fdrop
         ( zero_loc_array_offset | spike_interpolated_count )
\         chkvecsum?
\         if ."  zero+ interp_count is before this spike" then
         ( zero_loc_array_offset | spike_interp_count ) 8 + 
         \ advanced the zero loc index offset for the next spike
        repeat

        ( zero_ofs | spike_interp_count zero_interp_count )
        fswap f- drop
        ( | count_gap )  keep-looking?
        if
         ( -- | count_gap )
\         chkvecsum?
\         if
\           cr ." count gap from spike to zero+ = " fdup f.
\         then
         \ The interpolated count difference is 0.0E0 to approximately
         \ 30.0E0, depending on how much drift occurs between the
         \ asynchronous sound card sampling rate and the antenna
         \ switching rate. The unit is sound card sample counts, a
         \ non-negative difference between interpolated counts at a zero
         \ crossing and a preceding spike that caused it.

         \ Next, we store vector x,y coordinates for this zero
         \ crossing, and accumulate them in variables for averaging
         \ later in get-average-phase-vector-magnitude, where we divide by
         \ #section-spikes-found to get the average vector x and y
         \ coordinates.

         ( | fval ) fsamples/tone-cycle f@ f/ f2pi f* \ 20240326
         \ this angle is in radians
         \ corrected for #samples/tone-cycles no longer being exactly 30
         showvecdata?
         if
           cr spike# 1+ .  fdup radians>degrees f.
         then
         ( | radians ) fdup fsin fdup phase-angle-x cyc#offset + f!
         showvecdata?
         if
           ( | radians sinval ) fdup f.
         then
         ( | radians sinval ) sec-avg-vec-x f@  f+
         showvecdata?
         if
           ( | radians avgvecx+sinval ) fdup f.
         then
         ( | radians avgvecx+sinval ) sec-avg-vec-x f!
         ( | radians ) fcos fdup phase-angle-y cyc#offset + f!
         showvecdata?
         if
           ( | cosval ) fdup f.
         then
         ( | cosval )         sec-avg-vec-y f@  f+
         showvecdata?
         if
           ( | radians avgvecx+cosval ) fdup f.
         then
         ( | avgvecy+cosval ) sec-avg-vec-y f!
\         chkvecsum?
\         if
\           cr ." advance to next spike" \ .s f.s pause
\         then
         ( | )
         \ Advance the offset into the arrays:
         cyc#offset 8 + to cyc#offset
\         chkvecsum?
\         if
\          ."  next offset" cyc#offset .
\          pause
\         then
        else
         chkvecsum?
         if
           cr ." rubbertime_from_spike_to_zero_crossing:" fdup f.
           ." is past the end of the array for interpolated zero+ counts"
         then
         ( -- | rubbertime_from_spike_to_zero_crossing ) fdrop
        then
       else
        0 to keep-looking?
        chkvecsum?
        if
          cr ." no more zero's past spike#" spike# 1+ . spaxy \ 20240327
        then
        ( | spike_rubbertime ) fdrop
       then
       keep-looking?
     while
       spike# 1+ to spike# 
     repeat

    else
     chkvecsum? if cr ." no spikes found" then
    then

   \ check-all-spike-counts check-zero+counts check-vector-magnitudes
    showbadvector?
    if cr ." V:" bad-vector . ." S:" bad-spike . ." Z:" bad-zero+ . then
    showvecangles? chkvecsum? or
    if spaxy sva cvm batch-sec# ." sec#" . ." end of gpavs" pause cr then
    ;
: gpavs get-phase-angles-vector-sum ;
\ : dgpavs break: get-phase-angles-vector-sum ; \ 20230107

variable sec-avg-vec-angle  \ used only for csv charts
 \ an integer in deg*10 so we get 1 dec pt resolution in csv files
 \ We also deliver only 1 dec pt resolution in TaskD in the bearing
 \  report strings piped out to the web.

variable sec-avg-vec-mag \ integer scaled to 999, used only for csv charts

\ Bearing "quality" is measured by the length of the vector sum
\ of the phase angle vectors, which is maximum when all the vectors
\ point the same way, i.e., the sum max for the unit vectors is
\ simply the float value of n unit vectors, where
\ n = #zero-crossings-found, and when the
\ vectors are randomly scattered their vector sum magnitude
\ minimum is 0.0e0 (in theory).

fvariable f20  20 s>f f20 f!

: get-average-Doppler-tone-vec-angle
   \ Originally we did a batch section of 80 antenna rotations.
   \ Here in TaskA we process the 1st S16 stereo buffer quarter and we
   \ pass on the 2nd, 3rd and 4th quarters to tasks B, C, and D which
   \ will process them. TaskD processes the fourth buffer quarter,
   \ integrates its results, and pipes a message out to the web.

   \ NOTE: In gforth fatan2 is the inverse function of fsincos, i.e.,
   \       fsincos ( r1 -- r2 r3 ), where r2 = sin(r1) and r3 = cos(r1)
   \       fatan2 ( r1 r2 -- r4 ), where r4 = atan(r1/r2), so r1 abd r2
   \       must be a sin and a cos value -- they can't be arbitrary
   \       numbers as it is possible for fatan.    20220618
    sec-avg-vec-x f@  sec-avg-vec-y f@
    kfatan2  radians>degrees \ no fatan2 in the GFTP
    f10 f*
    \ scaled up to show 1 decimal place in cvs charts
    f>s   sec-avg-vec-angle ! ;
: gapva get-average-Doppler-tone-vec-angle cr sec-avg-vec-angle @ . ;

: get-average-phase-vector-magnitude
    \ used for reports to TaskD and csv charts
    #section_zero+crossings 0 >
    if
     sec-avg-vec-x f@ fdup f* sec-avg-vec-y f@ fdup f* f+ kfsqrt
     999 s>f f* #section_zero+crossings s>f f/ f>s \ 20240327
     \ using 5 digits for vector X & Y coordinate precision
     \ but only 3 digits in csv charts
    else
      0
    then
    sec-avg-vec-mag !
    ;
: gapvm get-average-phase-vector-magnitude sec-avg-vec-mag @ . ;

\ GFTP lacks 2! so here we simulate it:
: k2! ( lo hi adr -- )  2dup ! ( lo hi adr ) nip ( lo adr ) 4 + ! ;

: kfill ( adr #bytes byteval -- )
    rot rot ( byteval adr #bytes -- )  0
    do ( byteval adr ) 2dup c! 1+  loop  2drop ;

\ GFTP lacks >r r> r@  so I had to fake them
\ Later I no longer needed the traditional Forth numeric ASCII display.
\ 256 constant fake-return-stack-len
\ variable unused0 create fake-return-stack  \ 20220623
\  fake-return-stack-len allot

\ variable fake-return-stack-ptr
\ changed from value to variable  20220623

\ : init-fake-ret-stack-ptr
\    fake-return-stack fake-return-stack-len + fake-ret-stack-ptr ! ;

\ init-fake-ret-stack-ptr

\ : k>r ( n -- )  fake-ret-stack-ptr @ cell - dup
\    ( n decremented_ret_stack_ptr_val=adr_at_fake_ret_stack )
\    fake-ret-stack-ptr ! ( n fake_ret_stack_adr ) ! ;
\ : dbgk>r break: k>r ;

\ : kr> ( -- n ) fake-ret-stack-ptr @ ( ret_stack_adr )
\    cell + dup fake-ret-stack-ptr ! ( incremented_ret_stack_adr ) @ ;
\ : dbgkr> break: kr> ;

\ : kr@ ( -- n )  fake-ret-stack-ptr @ @ ;

FALSE value dbg?

13 value $csv-data-values-len
\ for spreadsheet evaluation of TaskA performance
\ Format: angle comma angle_vec_len comma max_tone_val CR
\     13 =  4   + 1      + 3        + 1      + 3      + 1

\ We use 5 digit angles for sending to TaskD and 4 digit angle vector
\ magnitude to avoid resolution loss when averaging mag values from tasks
\ A, B, C, and D.

\ Max Doppler tone peak and the average amgle vector length are useful
\ as bearing quality indicators.

create $csv-data-values
$csv-data-values-len allot
\ $csv-data-values $csv-data-values-len 1- 32 kfill
$0A $csv-data-values $csv-data-values-len 1- + c!
\ pre-store commas between data entries
44 $csv-data-values 4 + c! \ past 4-dig angle
44 $csv-data-values 8 + c! \ past 4-dig angle, comma, 3-dig

$csv-data-values-len #batch-buf-sections *
constant csv-data-buf-len
create csv-data-buf csv-data-buf-len allot
csv-data-buf csv-data-buf-len 32 kfill \ no fill in the GFTP  20230612

\ GFTP doesn't have stdout nor stdin, but fortunately it has
\ accept and type in case we need to test interactively.

0 value csv-data-fid
create csv-data-file-name  256 allot
create csv-data-path-name  128 allot

: set-csv-data-path-name
    csv-data-path-name 128 erase
    s" ./" csv-data-path-name place
    ;

: set-csv-data-file-name
    csv-data-file-name 256 erase
    set-csv-data-path-name
    csv-data-path-name count csv-data-file-name  place
    s" TaskA" csv-data-file-name +place \ 20231221
   \ Time & data tagging of web reports is done only in TaskD
   \ and also when outputing csv data for spreadsheets and raw data
   \ for audacity viewing.  20230827
    utime 16 peel-off-digits
    $digits $utime 1+ 16 cmove  16 $utime c!
    $utime count csv-data-file-name +place
    s" .csv" csv-data-file-name +place
    ;

: open-csv-data-file
    set-csv-data-file-name
    csv-data-file-name count r/w open-file ( fid wior )
    if
        ( fid=0 ) drop
        csv-data-file-name count r/w create-file
        ( fid wior )
        if
            cr ." Failed to create "
            csv-data-file-name count type
            ( fid=0 ) drop quit
        then ( fid )
    then  ( fid ) to csv-data-fid
    ;

: close-csv-data-file   \ 20221228
    csv-data-fid 0<>
    if
        csv-data-fid close-file ( wior )
        if
            cr ." Failed to close csv-data-file"
        else
            0 to csv-data-fid
        then
    else
        cr ." Null fid for csv-data-file"
    then
    ;
: ccdf close-csv-data-file ;

0 value maxtonepeak

17 constant $avgDopplervector&maxtone-len
\ $avgDopplervector&maxtonepeak is used to send TaskA's averaged Doppler
\ tone's 2D vector in Cartesian coordinates to TaskD, the number of zero+
\ crossings used when averaging, and the maximum Doppler tone's peak value
\ during the 1st quarter (of duration 1/80th second) of a batch buffer
\ section of duration 1/20th second.

\ Format: +/- vec-X +/- vec-Y #zero+ maxtone
\ 17 =     1    5    1    5     2      3
create $avgDopplervector&maxtone $avgDopplervector&maxtone-len allot

\ TaskD averages the Doppler tone 2D vectors reported via three files
\ from Tasks A, B, and C, and it includes its own averaged 2D vector
\ derived during processing of the 4-th quarter of the 50ms sound card
\ captured S16 buffer.

\ We use 5-digit averaged FIR filtered Doppler tone phase angle
\ X,Y coordinates during one quarter of a 1/20th sec sound card
\ capture in order to improve the angle resolution when averaging
\ the results from the four tasks A, B, C, D.

\ The averaged Doppler bearing is the phase angle of the sum of 2D bearing
\ vectors acquired during 1/80th second for each task. Each vector sum
\ is normalized as a vector of unit magnitude by dividing by
\ #section_zero+crossings, which is often the number of spikes during
\ the buffer quarter, but not always, because of how the floating
\ point interpolated spike and zero crossings are distributed.

\ As the aproximately 20 unit vectors are averaged over the 1/80th sec
\ duration of a sound card buffer quarter, the averaged vector is of
\ magnitude 1 when the phase angles are all the same, and when the
\ Doppler tone's phase angle randomly fluctuates the averaged vector's
\ magnitude is nearly zero (or exactly zero in the case of unit vectors
\ uniformly distributed along a unit radius circle). This provides us
\ with an excellent measure of bearing quality.

\ TaskD proportionally adds the vector sums from Tasks A, B, C, D by
\ multiplying each task's 2D unit vector by that task's
\ #section_zero+crossings value, then TaskD divides the total vector sum
\ by the sum of the four tasks' #section_zero+crossings values so as to
\ normalize the total vector sum to a vector in the range
\ 0.0e0 .... 1.0e0. TaskD computes the resulting vector's angle and
\ magnitude. It casts the magnitude as it as a text string in the range
\ 000 to 999 and the angle as a text string in the range
\ 0 to 3599 (degrees *10) and pipes out a bearing data report to Robin's
\ website www.rdf.kn5r.net .

200 ( for 1 decimal point ) value angle-offset

fvariable f1000000  1000000 s>f f1000000 f!

: prepare-report-string-for-TaskD
   \ cr ." x=" sec-avg-vec-x f@ f. ." y=" sec-avg-vec-y f@ f. pause
    \ we use 5-digit Doppler tone vector X,Y coordinates for sending to
    \ TaskD which then combines averages from the four concurrent tasks
    sec-avg-vec-x f@ f1000000 f@ f* f>d
   \ 2dup d.
     5 peel-off-signed-digits   $digits
    ( adr ) $avgDopplervector&maxtone 6 cmove
    sec-avg-vec-y f@ f1000000 f@ f* f>d
   \ 2dup d.
     5 peel-off-signed-digits   $digits
    ( adr ) $avgDopplervector&maxtone 6 + 6 cmove
    #section_zero+crossings s>d 2 peel-off-digits  $digits
    ( adr ) $avgDopplervector&maxtone 12 + 2 cmove \ zero+ crossings
    maxtonepeak ( s ) s>d  3 peel-off-digits   $digits
    ( adr ) $avgDopplervector&maxtone 14 ( =1+5+1+5+2 ) + 3 cmove
   \ $avgDopplervector&maxtone $avgDopplervector&maxtone-len
   \ cr type pause      \ 20231210
   ;
   
: send-angle&mag&maxtonepeak-to-TaskD
    $avgDopplervector&maxtone $avgDopplervector&maxtone-len
   \ cr 2dup type pause
    TaskAavgstoTaskD-data-fid
    ( adr count fid ) write-file ( wior ) throw
 ;
: samt send-angle&mag&maxtonepeak-to-TaskD ;
: dsamt break: send-angle&mag&maxtonepeak-to-TaskD ;

\ TRUE value dbg-isbs?

0 value spike-ptr  0 value signal-ptr

: initialize-signal-batch-section-buf-float-values
    spike-sig-batch-section-ptr to spike-ptr
    orig-sig-batch-section-ptr to signal-ptr

    S16-sig-batch-section-ptr
    \ source address of the 16-bit buffer section

   \ We read from the sound card, or from a prerecorded S16sereo file,
   \ a number of samples for a selected number of ant rot cycles
   \ comprising a "section" of a "batch" of samples and we now convert
   \ them to floats in a the part of signal-batch-section-buf for the
   \ selected batch section.

  \ NOTE: After switching to a stereo sound card, we cast 16-bit receiver
  \ audio values as 64-bit floats from the LEFT channel 625us spikes as
  \ also 64-bit floats read in from the RIGHT channel.

    #batch-section-samples-to-get
    0  \ start at 1st sample
    do
        ( srce_adr ) dup w@
        dup 2^15 and if 2^16 - then s>f  fscale-fac f@ f/
       \ no fconstant in the gforth-transpiler so we had use a
       \ float variable, since the GFTP doesn't support gforth floats
        ( srce_adr | scaled_sigval ) signal-ptr dup f!
        ( src_adr sigptr ) signal-float-data-len + to signal-ptr
        ( src_adr ) 2 + dup w@
        dup 2^15 and if 2^16 - then s>f  fscale-fac f@ f/
        ( srce_adr | scaled_spikeval ) spike-ptr dup f!
        ( src_adr+2 spike-ptr ) signal-float-data-len + to spike-ptr
        ( srce_adr+2 ) 2 +
    loop ( srce_adr ) drop
  ;
: isbs initialize-signal-batch-section-buf-float-values ;
\ : disbs break: isbs ;

\ The following are used for TaskA's performance on its buffer quarter
\ when csv chart evaluation is enabled.
falsE value csv?

: convert-Doppler-tone-vec-angle-to-csv-string
    sec-avg-vec-angle @  angle-offset +  3600 mod
    ( n ) s>d  4 peel-off-digits
    $digits $csv-data-values 4 cmove
    \ for csv chart evaluation 4 angle digits is enough
   ;

: convert-Doppler-tone-vec-mag-to-csv-string
      sec-avg-vec-mag @
      ( n ) s>d  3 peel-off-digits
      $digits $csv-data-values 5 + 3  cmove
      \ go past 4 angle digits and a comma
      \ for csv chart evaluation 3 vecmag digits is enough
    ;

: convert-maxtonepeak-to-csv-string
    maxtonepeak s>d 3 peel-off-digits
      $digits $csv-data-values 9 ( =4+1+3+1 ) + 3 cmove
      \ go past 4 angle digits, a comma, 3 vec mag digits digits and
      \ another comma
    ;

: append-csv-string-to-data-buf
     $csv-data-values  csv-data-buf
     $csv-data-values-len batch-sec# * + \ adr for this section data
     ( src_adr dest_adr ) $csv-data-values-len cmove
     ;

: prepare-csv-file-string
      get-average-Doppler-tone-vec-angle
      convert-Doppler-tone-vec-angle-to-csv-string
      convert-Doppler-tone-vec-mag-to-csv-string
      convert-maxtonepeak-to-csv-string
      ;

: write-out-last-batch-data-to-files
\ NOTE: We write out raw data buffers to files during
\ debugging for viewing spikes using audacity to check that they line up
\ vertically in the original signal and also to see where a vertical
\ line passes through the FIR filtered trace indicating the Doppler tone
\ phase angle there.

    orig-sig-batch-section-ptr #batch-section-float-bytes  \ 20230821
    orig-data-fid write-file ( wior ) throw

   \ spike data is read from the right channel of a stereo
   \ sound card or from every other 16-bit datum in a precorded
   \ stereo data file
    spike-sig-batch-section-ptr #batch-section-float-bytes  \ 20230821
    spike-data-fid write-file ( wior ) throw

    filtered-buffer-section-ptr #batch-section-float-bytes
    filt-data-fid write-file ( wior ) throw
    ;
: wolb write-out-last-batch-data-to-files ;
: dwolb break: write-out-last-batch-data-to-files ;

0 value FIR-input-ptr   0 value FIR-output-ptr

fvariable fmaxtonepeak
  \ We scale Doppler tone peak up to show 3 decimals
  \ NOTE: The FIR filter output values are scaled to +-1.0e0

: kfmax ( | r1 r2 -- | larger_of_r1&r2 ) fover fover f<   \ 20220621
    ( | r1 r2 -- flg )
    if
        fswap
        ( | r2 r1<r2 )
    then  \ the lesser of r1 and r2 is at float stack top
    fdrop ;

: kmax ( n1 n2 -- larger_of_n1&n2 ) over over <  \ 20220707
    ( n1 n2 -- flg )
    if
        swap
        ( n2 n1<n2 )
    then  \ the lesser of n1 and n2 is at TOS
    drop ;

: erase-filtered-buffer  filtered-buffer filtered-buffer-len erase ;

: do-FIR-filter
         #batch-section-samples-to-process 0
         do
          \ Run FIR filter on #taps signal buffer samples for this
          \ batch buffer section

          \ clear FIR filter accumulator
          0 s>f  FIR-filtered-value f!

          FIR-input-ptr    coeff-floats-array
          #taps ( 311 ) 0
          do
            ( in_adr tap_adr ) over f@  dup f@
            ( in_adr tap_adr | sigval FIRcoeff ) f*
            ( in_adr tap_adr | float_sig_val*float_coeff )
            FIR-filtered-value f@  f+  FIR-filtered-value f!
            ( in_adr tap_adr ) coeff-len +
             swap signal-float-data-len - swap
          loop  2drop

          FIR-filtered-value f@  fscale-fac1 f@ f*
          ( | fval ) fdup FIR-output-ptr f!
          \ stored latest filtered value

          \ Now update the max Doppler tone peak so far during this batch
          \ section
          ( | fval ) fmaxtonepeak f@  kfmax
          \ NOTE: no max in the GFTP
          ( | updated_fval ) fdup fmaxtonepeak f!
          \ NOTE: The FIR filter output is scaled to be +-1.0e0
          ( | fval ) f1000 f@ f* \ scaled up to show 3 decimals
          ( fval*1000 ) f>s  maxtonepeak kmax to maxtonepeak
          \ NOTE: no max in the GFTP

          \ Advance FIR input and output pointers to start FIR
          \ filtering at the next smoothed signal sample of this section
          FIR-input-ptr signal-float-data-len + to FIR-input-ptr
          FIR-output-ptr signal-float-data-len + to FIR-output-ptr
         loop
         ;  \ end of loop on #batch-section-samples

\ : wrcsv
\    csv-data-buf csv-data-buf-len csv-data-fid write-file throw ;

\ ====================================================================
\ no longer needed debugging tools to identify where the run time code
\ was writing on top of dictionary definitions
\ : typewordname ( word's_tick_adr -- )
\    >name 8 + dup 4 - @ $ffffff and type ;
\
\ variable prev-word1adr  variable prev-word2adr  variable prev-word3adr
\ variable prev-word1val  variable prev-word2val  variable prev-word3val
\ \ ' orig-sig-batch-section-ptr >name dup prev-word1adr !
\ ' open-data-to-TaskB,C,D-files >name dup prev-word1adr !
\  @ prev-word1val !
\ \ ' S16-sig-batch-section-ptr >name dup prev-word2adr !
\ ' S16toTaskB-data-fid >name dup prev-word2adr !
\  @ prev-word2val !
\ \ ' batch-sec# >name dup prev-word3adr !
\ ' TaskAavgstoTaskD-file-name >name dup prev-word3adr !
\  @ prev-word3val !

\ 0 value chk-word#  0 value clob-word#   0 value chk-line#

\ : clobber-report
\    chk-word#
\    if
\       cr ." clobbered prev-word link at checking line#"
\       chk-line# . cr  clob-word#
\       case
\       1 of
\            ." orig-sig-batch-section-ptr"
\            prev-word1val @  prev-word1adr @ @
\         endof
\       2 of
\            ." S16-sig-batch-section-ptr"
\            prev-word2val @  prev-word2adr @ @
\         endof
\       3 of
\            ." batch-sec#"
\            prev-word3val @  prev-word3adr @ @
\         endof
\       endcase
\       ( n1 n2 ) ."  is:" . ."  instead of:" . quit
\    then
\    ;

\ : prev-word-clobbered? ( n -- )
\    ( n ) to chk-line#  4 1
\    do
\      i to chk-word#
\      prev-word1adr @ @ dup 0= swap prev-word1val @ <> or
\      if i to clob-word# then
\      prev-word2adr @ @ dup 0= swap prev-word2val @ <> or
\      if i to clob-word# then
\      prev-word3adr @ @ dup 0= swap prev-word3val @ <> or
\      if i to clob-word# then
\      clob-word# chk-word# = if clobber-report then
\    loop ;
\ ====================================================================

TRUE value writeS16data-toTaskB,C,Dfiles?
\ If not, we are running TaskA to check out its performance without
\ changing saved files for running tasks B, C, and D.

#batch-section-samples-to-process  4* dup
 value #batch-sectionS16bytes
( #bytes ) #FIRfilter-history-stereo-data-bytes +
 value #bytes-to-send \ 20230822

\ 0 value temp-fid
\
\ : write-S16stereo-buf-values-to-text-file ( adr #bytes fid )
\    to temp-fid
\    ( #bytes ) 2 / ( #S16values )  0
\    do
\       ( adr ) dup w@ s>d 5 peel-off-digits
\       ( adr ) $digits ( adr stradr ) 5 temp-fid write-file throw
\       ( adr ) 2 +
\    loop ( adr ) drop ;

\ FALSE value piping-data-to-TaskB?
\ for piping data serially > TaskB > TaskC > TaskD

: send-S16stereo-buf-remainder-to-TasksB,C,D
   \ restored writing binary data to other tasks  20230906
    S16-sig-batch-section-ptr #FIRfilter-history-stereo-data-bytes -
   \ writeS16data-toTaskB,C,Dfiles?
   \ if
       \ Write S16stereo buffer quarter data to individual files
       \ for TaskB, TaskC and TaskD.

       ( adr ) #batch-sectionS16bytes + \ skip past TaskA part 20240316
       #FIRfilter-history-stereo-data-bytes - \ back up FIR history
       ( adrB ) dup #bytes-to-send
       ( adrB adrB #bytes ) S16toTaskB-data-fid write-file throw

      \ write-S16stereo-buf-values-to-text-file
      \ This was done when trying out sending the 2nd S16 buffer quarter
      \ to TaskB in a text file.

       ( adrB ) #batch-sectionS16bytes +
       ( adrC ) dup #bytes-to-send
       ( adrC adrC count ) S16toTaskC-data-fid write-file throw

      \  write-S16stereo-buf-values-to-text-file
      \ This was done when trying out sending the 3rd S16 buffer quarter
      \ to TaskC in a text file.

       ( adrC ) #batch-sectionS16bytes +
       ( adrD ) #bytes-to-send S16toTaskD-data-fid write-file throw

      \ ( adrD count ) write-S16stereo-buf-values-to-text-file
      \ This was done when trying out sending the 4th S16 buffer quarter
      \ to TaskD in a text file.

       ( -- )
   \ else
   \   piping-data-to-TaskB?
   \   if
   \     \ Pipe remaining 3/4 of the S16stereo buffer to TaskB 20230821
   \     s" X" type
   \     ( adr ) #FIR-samples  #batch-section-samples-to-process 3 * +
   \    ( adr count ) 0
   \     do
   \       ( adr ) dup w@ s>d 5 peel-off-digits  $digits 5 type  2 +
   \     loop ( adr ) drop
   \   else
   \
   \   then
   \ then
  ;

FALSE value saving-S16stereo-data-file?

: run-FIR-filter-on-batch-section-buffer
    \ Initialize prev-sig-slope to something reasonable for the
    \ double loop in get-spikes to get it started the first time
    \ it is run.    20210817
    -1 s>f  prev-sig-slope f!

      erase-filtered-buffer \ 20230311
\ 1 prev-word-clobbered?

      #batch-buf-sections  0
      do
       i to batch-sec#
       \ set read and write buffer pointers for this section of this batch
       init-batch-buffer-section-ptrs

       0 to maxtonepeak  f0.0e0 fmaxtonepeak f!
      \ Now we read in stereo, so 16-bit samples 1,3,5,... are signal
      \ audio from the left channel and samples 2,4,6,... are spike
      \ signal from the right channel.   20230315
       S16-sig-batch-section-ptr
       #batch-section-stereo-bytes-to-read-from-card-or-file
      \ data-read-from-stereo-S16file?
      \ if
      \    S16-data-fid read-file ( #bytes_read wior )
      \    if
      \      cr ." S16 stereo file reading failure!"
      \      wolb  close-data-output-files  close-csv-data-file
      \      quit
      \    else
      \      ( #bytes_read )  drop
      \    then
      \ else
          sound-card-fid read-file ( #bytes_read wior )
          if
            cr ." sound card reading failure!"
            wolb  close-data-output-files  close-csv-data-file  quit
          else
             ( #bytes_read )  drop
          then
      \ then
\ 2 prev-word-clobbered?

         saving-S16stereo-data-file?
         if
           S16-sig-batch-section-ptr
           #batch-section-stereo-bytes-to-read-from-card-or-file
           S16-data-fid write-file ( wior ) throw
         then

      \ writeS16data-toTaskB,C,Dfiles?
      \ if
         send-S16stereo-buf-remainder-to-TasksB,C,D
         \ Before doing any data processing in this Task, get the other
         \ tasks started processing their parts of the S16stereo buffer.
      \ then

       initialize-signal-batch-section-buf-float-values  \ 20230101
\ 3 prev-word-clobbered?

      \ Skip looking for zero crossings if lack of signal received
      \ orig-sig-batch-section-ptr f@ f1000 f@ f* fabs f>d d0> \ 20230130
      \ if
         find-signal-spikes \ this sets #section-spikes-found
\ 4 prev-word-clobbered?

         interpolate-spike-counts
\ 5 prev-word-clobbered?

         \ begin getting signal data at the start of signals
         \ for this ant rot cycle of this batch section
         orig-sig-batch-section-FIRptr to FIR-input-ptr  \ 20230215
         filtered-batch-section-FIRptr to FIR-output-ptr
         \ The FIR filter will now work on sections of a batch of sound
         \ card captures; a section has 80 ant rot cycles of 30 samples
         \ each which will be read from the sound card into a 960
         \ samples long segment of the larger signal buffer.
         \ The buffer edges were set so as to fit within a part of the
         \ larger signal and filtered buffers so as to prevent having to
         \ check for a need to wrap back to past signal buffer history in
         \ circular order up to #taps slots backwards.

         do-FIR-filter
\ 6 prev-word-clobbered?
         find-Doppler-tone-neg-to-pos-crossings
         \ this sets #section_zero+crossings
         get-phase-angles-vector-sum
         get-average-phase-vector-magnitude

        \ writeS16data-toTaskB,C,Dfiles?
        \ if
           prepare-report-string-for-TaskD
           send-angle&mag&maxtonepeak-to-TaskD
        \ then

\ 7 prev-word-clobbered?
         dbg? if wolb then
         csv?
         if
           prepare-csv-file-string  append-csv-string-to-data-buf
         then

\ 8 prev-word-clobbered?
      \ then
      loop  \ end of loop on #batch-buf-sections for one batch
\ 9 prev-word-clobbered?

      copy-sig-buf-tail-to-head \ 20230621
    ;

: rffobsb
    run-FIR-filter-on-batch-section-buffer ;
: drffobsb break: rffobsb ;

: rffobsbs ( n -- )
   TRUE dup to writeS16data-toTaskB,C,Dfiles?
   if open-data-to-TaskB,C,D-files then
   \ if false we test TaskA without overwriting them

  \ FALSE to data-read-from-stereo-S16file?
   \ if false we get S16 stereo data from the sound card

   S16signal-buffer  S16signal-buffer-len erase
   csv? if open-csv-data-file then
   dbg? if open-data-output-files then
   saving-S16stereo-data-file? if open-S16stereo-data-file then

   ( n ) 0
   do
    run-FIR-filter-on-batch-section-buffer
    csv?
    if
      csv-data-buf csv-data-buf-len csv-data-fid write-file throw
    then
   loop
   dbg? if close-data-output-files FALSE to dbg? then
   csv? if close-csv-data-file FALSE to csv? then
   \ do them only once when requested while running >web
   saving-S16stereo-data-file?
   if
     S16signal-buffer S16signal-buffer-len S16-data-fid
     write-file ( wior ) throw  close-S16stereo-data-file
   then
   writeS16data-toTaskB,C,Dfiles? if close-data-toTasksB,C,D-files then
   ;
: drffobsbs break: rffobsbs ;

0 value quit-request
: >web ( n -- )
   FALSE to quit-request
   open-sound-card-input \ 20240409
   begin
    key?
    if
     key dup emit ."  KEY HIT"
     case
      27 of ."  ESC" FALSE to csv? FALSE to dbg? 1 to quit-request endof
      67 of ."  do csv" TRUE to csv? endof
      68 of ."  do dbg" TRUE to dbg? endof
      66 of ."  do csv & dbg" TRUE to csv? TRUE to dbg? endof
      83 of ."  save S16stereo file" TRUE to saving-S16stereo-data-file?
           endof
     endcase
    then
    ( n ) dup rffobsbs
    FALSE to dbg?  FALSE to csv?  FALSE to saving-S16stereo-data-file?
    quit-request 0=
   while
   repeat
   close-sound-card-input
   ( n ) drop
  ;

\ 10 rffobsbs
\ 3 >web
: run 3 >web ;
