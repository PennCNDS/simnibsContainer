# simnibsContainer

Containerized SimNIBS, base for Flywheel gear.

This container users SimNIBS 4, and is designed to run the Python workflow. It does not have MATLAB functions.

Other preprocessing is are provided by:

* [FreeSurfer 8.0.0](https://surfer.nmr.mgh.harvard.edu) (with `csvprint` patch)
* [flirt (FSL)](https://fsl.fmrib.ox.ac.uk)
* [AFNI](https://afni.nimh.nih.gov)

Use of the container and these tools is subject to their licensing conditions as documented at their respective sites. A FreeSurfer License file will be required at run time for all FreeSurfer operations.

A container image is available at
[DockerHub](https://hub.docker.com/repository/docker/cookpa/cnds-efield).


## Usage

From within the container:

```bash
ef_pipeline --bids_dir $PATH_TO_BIDS --sub $SUBJECT --ses $SESSION --fs_lic $PATH_TO_FREESURFER_LICENSE
```

or

```bash
ef_pipeline --help
```

### Input structure

The `--bids_dir` argument is not actually a BIDS dataset, but rather a path to a directory
containing a BIDS dataset called "rawdata". A directory "derivatives" will be created
alongside it.


## SimNIBS

See the main [SimNIBS page](https://simnibs.github.io/simnibs/build/html/index.html) for
more information on using SimNIBS, licensing, and citations to include when using SimNIBS.


