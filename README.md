STISEXTRACT (v1.3)
----------------------------------

J. Christopher Howk (U. Notre Dame, `jhowk@nd.edu`)  
Kenneth R. Sembach (STScI)

*Mar.  5, 2001 - Description of procedures, tar installation.*  
*Nov. 12, 2016 - Updated for GITHUB repository, commentary on current state of STIS extractions.*


I. INTRODUCTION:
----------------
STISEXTRACT is a set of IDL procedures designed to extract high-resolution echelle data from the Space Telescope Imaging Spectrograph (STIS), estimate the on-order background spectrum, and remove the background spectrum from the data.  The procedure is described by [Howk & Sembach (2000, AJ, 119, 2481)](http://adsabs.harvard.edu/abs/2000AJ....119.2481H).

This software is freely distributed to all interested parties. However, in return we ask the following: (1) Astronomers using this software should send us an email telling us they are doing so (so that we can announce any updates or prominent bug fixes). (2) In your papers discussing data reduced with our algorithm, please reference the Howk & Sembach (2000) paper. (3) Please inform us if you find any bugs, or if you make potentially important modifications to the code. In the latter case, please document your changes in the header and send us an email copy of the procedure.

II. INSTALLATION:
-----------------

The steps to installing the STISEXTRACT distribution are as follows.

#### Installation from tar file:

1) Extract the STISEXTRACT tar file:  

		tar -xvfz stisextract_v1.3.tgz  

This makes a directory tree within the current directory. The STISEXTRACT distribution is placed in a subdirectory `stisextract/`.

#### Installation from GITHUB:

1) Create a directory to hold the code. (The description below assumes the distribution is housed in a directory `stisextract/`).

2) From within that directory, clone the GITHUB distribution:

    git clone https://github.com/jchowk/STISextract.git

#### Finishing the installation:

3) Edit your IDL startup file so that the !help_path includes the `stisextract/help/` directory. *Example:*  

	!help_path= "/Users/howk/idl/stisextract/help:"+!help_path

4) Make sure your `.idlstartup` file is located in your home directory or else set the appropriate path with the unix environment variable `IDL_STARTUP`   *Example:*

		  setenv IDL_STARTUP /home/vulpecula/howk/.idlstartup

5) Make sure that your `IDL_PATH` environment variable includes the `stisextract/` directory.    *Example:*

		  setenv IDL_PATH +/home/vulpecula/howk/stisextract:$IDL_PATH  

The leading "+" symbol allows IDL to search down the directory tree established by STISEXTRACT.

Note that these steps can be accomplished in slightly different ways if you are an expert IDL user. You may choose not to implement the installation of the help paths if this is unimportant to you.

III. REDUCING YOUR STIS DATA:
-----------------------------

Using STISEXTRACT to reduce your high-resolution STIS echelle mode data is a two part process.  The first step is to produce the rectified two dimensional images using the standard CALSTIS distribution within IRAF (this can be obtained from the STScI web page).  The second is to run STISEXTRACT from within IDL.  We detail these steps below:

1) Create rectified two dimensional images using the standard CALSTIS:  

First you must use the standard STScI `CALSTIS` distribution within IRAF to produce rectified two dimensional images of each spectral order within your observation.  These images will be stacked within a FITS file entitled:
	rootname_x2d.fits  -or- rootname_sx2.fits
where `rootname` is the STScI archive rootname for your particular observations.  The latter file type is produced if you have multiple exposures within the same observation and requires the header keyword `RPTCORR` to be set to `PERFORM` (more on this below).  These files are created from:
	`rootname_raw.fits (rootname_wav.fits)`
The `_wav` file is only present if a wavelength image was created. The standard processing done by STScI before sending you your data typically do not produce the rectified images discussed above.

The first step in producing the `_x2d` or `_sx2` files for an observation is to adjust several values in the image headers.  Header keywords can be adjusted using the IRAF task `hedit`:  

	hedit filename KEYWORD NEWVALUE update+

(*Note:* header keywords can also be updated in IDL, Python, etc. We describe the approach in IRAF here since CALSTIS is run through IRAF in these examples). We suggest setting the following:

	IRAF> hedit rootname_raw.fits[0] X2DCORR PERFORM update+
	IRAF> hedit rootname_raw.fits[0] RPTCORR PERFORM update+

The first is absolutely essential: without it no `_x2d` files will be produced.  The second will coadd all of the exposures within a given observation before extraction.  STISEXTRACT is currently not able to recognize multiple exposures in an `_x2d` file.

The next step is to make sure that you have the appropriate reference files for recalibration and that they are in a directory IRAF will recognize.  This is discussed in the CALSTIS help pages within IRAF. We recommend making sure you are always using the "best" calibration reference files.  You can download a list of appropriate reference files for a given observation at the web page
	http://www.stsci.edu/cgi-bin/cdbs/getref.cgi
which is the same as using the IRAF task `getref` at STScI.  You can then use `upref` to load the downloaded information into your image headers.  See the `upref` help pages within IRAF.  Be sure you have the appropriate reference files before trying to recalibrate your data; you may need to request the best reference files from the HST data archive.

After adjusting the image headers to reflect your choice of reference files and processing options, simply run the following:

	IRAF> calstis rootname_raw.fits

This should, if all goes well, produce the required `_x2d` or `_sx2` data files.


2) Extract your spectra using the STISEXTRACT software within IDL:

This is the easy part.  To run the extraction software distributed within STISEXTRACT, do the following within IDL:

	IDL> stisdriver, 'rootname'

where rootname should be replaced by the STScI archive rootname of your data.  This will go through each order in the `_x2d` file (updating you on its progress as it goes) and derivie the on-order background, subtract it from the gross data, and write the results to an IDL save file.  It will also output a postscript file showing the net and background fluxes for each spectral order (three orders to a page). This postscript file is stored in `ROOTNAME.ps` (where `ROOTNAME` is the archival rootname in all caps).  If you wish to use an `_sx2` file, use the following call to `stisdriver`:

	IDL> stisdriver, 'rootname', /summed

By default, versions 1.3 and later of this software identify the spectral trace in a 2D image by fitting a Gaussian profile to the average cross-dispersion profile of the image.  These versions also look at the residuals of this Gaussian fit and attempt to identify other interloping spectral orders that might adversely affect the fit to the background.  If such interlopers are present and near the edge of the image, these versions of the software mask out the interloping orders in the background fitting process.  

This approach to identifying the spectral trace of the order of interest and any interlopers is a slight departure from the algorithm reported in Howk & Sembach (2000).  One can run the extraction routines using the older method of identifying spectral traces by doing the following:

	IDL> stisdriver, 'rootname', /nogauss

It should be noted that the new approach is more robust to the use of non-optimal CALSTIS reference files.

The series of routines driven by this procedure will produce one IDL save file for each order within your observations.  Each file is named: `rootname.mmm.save` where `mmm` is the three digit spectral order contained in the save file. To access these data, type:

	IDL> restore,'rootname.mmm.save'

This will read the following one-dimensional IDL variables into your
system:

	wave  -- Wavelength array in Angstroms.
	gross -- Raw extracted flux before background subtraction
	bg    -- Derived on-order background
	flux  -- Derived net flux (=gross-bg)
	err   -- Formal error array (does not include background error)
	order -- Current spectral order mmm.

If you would rather have the data saved to a series of ascii files named with the convention	`rootname.mmm.dat` you can run the stisdriver routine with the following keyword:

	IDL> stisdriver, 'rootname', /ascii

This will produce ascii files with columns corresponding to the wave, gross, flux, err, and bg vectors described above (in that order). Currently the software does not automatically produce a postscript plot when using ascii files for output.  This is because reading in the ascii files for the number of files produced by our routines takes a significant amount of time.  One can produce the postscript plot for a given observation after producing the output ascii files by doing the following:

	IDL> plotorders, 'rootname', /ascii

Should you decide to convert save files of an observation to ascii at some later point, simply type

	IDL> stis_asciiconvert

and all of the information in the IDL save files in the current directory will be copied to the appropriate ascii files.

What you do from this point is up to you, but you have in your hands the end result of our extraction software.  Minimal help pages have been created detailing the purposes of each of the procedures in the STISEXTRACT distribution.  These can be accessed through the old-style IDL help by typing:

	IDL> widget_olh

or

	IDL> man

Also, most of the procedures will give a calling sequence by simply typing the procedure name with no arguments.  For example:

	IDL> stisdriver

produces:
```
  STISDRIVER, rootname, /summed, /skip, /ascii, /nogauss

  *Inputs:
     rootname -- STIS _x2d or _sx2 rootname.


  *Keywords:
    /summed   -- Use _sx2 FITS file.
    /ascii    -- Output ascii files rather than IDL save files.
    /skip     -- Skip the first order of the observation.
    /nogauss  -- Do not use Gaussian to identify spectral trace.
```		

IV. NOTES ON THE NEED FOR THIS SOFTWARE AND THE STATE OF CALSTIS.
------------------------------

Since the time when STISEXTRACT was developed, STScI has released versions of CALSTIS that make use of the scattered light removal algorithms developed by the STIS Instrument Definition Team (IDT). This approach, which follows a full modeling of the scattered light using pre-flight measurements of the scattering properties of the echelle and cross-dispersion gratings. CALSTIS now does a good job of subtracting an appropriate background in the echelle gratings. The spectral extraction from the STScI-released CALSTIS should *always* be used when working with the intermediate resolution E140M, E230M grating data. For the E140H and E230H grating data, both approaches do well. The CALSTIS extraction performs better at the bluer wavelengths (esp. <1300 Ang). However, there is evidence based on the shapes of the zero-levels of strongly-saturated lines that STISEXTRACT performs slightly better at >1500 Ang or so. In both cases, one should carefully consider the shapes of the lines when great precision is required.

V. REPORTING ERRORS AND BUGS:
------------------------------

Error and bug reports should be sent to: `jhowk@nd.edu`. Pull requests may also be submitted through GITHUB.

VI. THANKS:
----------

Thanks to J. Lauroesch and D. Meyer for testing the early versions of this distribution and identifying several areas for fixes.  Thanks also to the file-access suggestion from W. Landsman, which has allowed us to increase the speed of these routines significantly.
