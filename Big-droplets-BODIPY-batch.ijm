// Define the directories for input and output images
dir1 = getDirectory("1");
dir2 = getDirectory("2");

// Get the list of files in the input directory
list = getFileList(dir1);

// Enable batch mode for faster processing (suppresses image display)
setBatchMode(true);

// Loop through each file in the input directory
for (g = 0; g < list.length; g++) {
    showProgress(g + 1, list.length); // Show progress of processing
    open(dir1 + list[g]); // Open the current file

    // Clean-up before processing the current image
    roiManager("reset");
    run("Clear Results");

    // Retrieve and store the title of the current image for later use
    title = getTitle();

    // Split channels of the image assuming it's a multi-channel image
    run("Split Channels");
    selectWindow("C2-" + title);
    rename("red"); // Rename the second channel (assumed to be red) and close it as it's not needed
    close();
    
    // Process the first channel (assumed to be BODIPY staining)
    selectWindow("C1-" + title);
    rename("BODIPY");

    // Set the scale of the image to known parameters
    run("Set Scale...", "distance=15.3846 known=1 unit=micron");
    run("Duplicate...", " "); // Duplicate the image for processing
    rename("Droplets BODIPY");

    // Subtract background and enhance contrast to prepare for droplet detection
    selectWindow("Droplets BODIPY");
    run("Subtract Background...", "rolling=50");
    run("Enhance Contrast", "saturated=0.35");

    // Convert to 8-bit and duplicate for creating a mask for droplet detection
    run("8-bit");
    run("Duplicate...", " ");
    rename("mask droplets");
    selectWindow("mask droplets");
    run("Subtract Background...", "rolling=10");
    run("Unsharp Mask...", "radius=3 mask=0.90");

    // Auto-thresholding to convert to binary mask, with user input for min threshold
    setAutoThreshold("Default dark stack");
    if (g == 0) {
        minTresh = getNumber("minTreshold", 100);
    };
    setThreshold(minTresh, 2000);
    run("Convert to Mask");
    run("Watershed"); // Apply watershed to separate touching objects

    // User input for min size of droplets, then analyze particles to detect droplets
    if (g == 0) {
        minSize = getNumber("minSize", 10);
    };
    run("Analyze Particles...", "size=" + minSize + "-1000 pixel circularity=0.6-1.00 add");

    // After detection, perform measurements on the original droplet image
    close("mask droplets");
    selectWindow("Droplets BODIPY");
    run("Subtract Background...", "rolling=50");
    run("Enhance Contrast", "saturated=0.35");
    run("Set Measurements...", "area redirect=None decimal=3");

    // Measure properties of detected droplets and flatten image for output
    roiManager("Deselect");
    roiManager("measure");
    roiManager("Show All without labels");
    run("Flatten");

    // Save processed image and results to the output directory
    saveAs(".tiff", dir2 + "droplets " + title + ".tif");
    saveAs("results", dir2 + "droplets " + title + ".csv");

    // Close all open images to free memory for the next iteration
    close("*");
};
