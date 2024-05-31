# edfEEG2024

`edfEEG2024` is a MATLAB script designed to analyze EEG/EMG data ('.edf' format) in mice for detection of sleep states, epileptiform spike-wave discharges (SWD), and generalized tonic-clonic seizures (GTCS).

#### Author:
[Dr. Yueqing Peng](https://www.pathology.columbia.edu/profile/yueqing-peng-phd)

![edfEEG2024](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/edfEEG2024.png)

### Table of Contents
| Section                                                                                 |
| --------------------------------------------------------------------------------------- |
| [Installation](#installation)                                                           |
| [Sleep scoring](#sleep-scoring)                                                         |
| [Re-scoring previously scored time windows](#re-scoring-previously-scored-time-windows) |
| [Troubleshooting](#troubleshooting)                                                     |

## Installation

### Install MATLAB and Required Add-Ons

1.	Visit https://matlab.mathworks.com
  * For Columbia/Barnard undergraduates, sign in using your university credentials
2.	Download and install MATLAB
3.	Open MATLAB. In the ‘Home’ tab at the top, click on ‘Add-Ons’
4. Search and install the following add-ons:
  * Curve Fitting Toolbox
  * DSP System Toolbox
  * Image Processing Toolbox
  * Parallel Computing Toolbox
  * Signal Processing Toolbox

![Add-ons](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/add-ons.png)
**Figure 1.** *'Add-Ons' option at the top 'Home' tab of the MATLAB program.*

### Download the edfEEG2024 script

1. At the top of this repository, click the green ‘<> Code’ button, then click ‘Download ZIP’
2. Extract the subdirectory `/edfEEG2024/edfEEG2024/` found inside the '.zip' to the MATLAB folder, which is found in the ‘Documents’ folder by default (e.g. ‘/Users/davidrivas/Documents/MATLAB’)
3. Consider watching or starring this GitHub repository for new updates to the script


## Software guide

### Sleep scoring

1. Inside the ‘edfEEG2024’ folder, open the `edfgui.m` file with MATLAB
2. In the ‘Editor’ tab at the top, click ‘Run’. The GUI window should now appear
  * Troubleshooting (refer to [troubleshooting section](#troubleshooting) for more details):
    * If the GUI doesn’t appear, check if any red error messages were output in the MATLAB ‘Command Window’
    * Be sure the [required add-ons listed in step 4 of the installation section](#install-matlab-and-required-add-ons) were installed
    * If the GUI window is larger than your screen and isn’t entirely visible, increase your monitor resolution
  ![GUI](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/gui.png)
  **Figure 2.** *The edfEEG2024 GUI window should appear after running the `edfgui.m` code.*
3. In the GUI, click on ‘Open File’. Locate and open the ‘.edf’ file you’d like to analyze
4. In the ‘Parameter’ section, choose the ‘Start(min)’ and ‘End(min)’ time window you would like to analyze. The script analyzes data in 60min time windows
  * If this is the first time opening the file for analysis, leave the ‘Start(min)’ and ‘End(min)’ at the default ‘0’ and ‘60’ values, respectively.
  * If you would like to analyze the second hour, set the ‘Start(min)’ and ‘End(min)’ at ‘60’ and ‘120'
5. Click ‘View Data’. A new figure titled ‘Original EEG data’ will appear
  ![Orignal EEG Data](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/orig-eeg-data.png)
  **Figure 3.** *After clicking 'View Data', the figure 'Original EEG data' will appear in a separate window.*
6. Evaluate the signal of both EEG channels (in this example, ‘EEG EEG1A’ & ‘EEG EEG2A’) and identify the channel with the largest amplitude. In the example above (**Figure 3**), this is ‘EEG EEG2A’ (highlighted in red). Make note of this, then close the figure window.
7. In the ‘File’ section, for the ‘EEG:’ option, select the EEG channel you'd like to analyze from the dropdown menu (e.g. EEG EEG2A). ‘ref:’ selects a reference channel. If you're not using a reference channel, leave ‘ref:’ as the default ‘N/A’ option.
  * **Note:** Once you choose an EEG channel from the dropdown menu, this will be the EEG channel used for the rest of the analyses for that mouse/experiment
8. In the ‘File’ section, for the ‘EMG:’ option, select the EMG channel (e.g. ‘EMG EMG’) from the dropdown menu. ‘ref:’ selects a reference channel. If you're not using a reference channel, leave ‘ref:’ as the default ‘N/A’ option.
9. In the ‘Function’ section, make sure the ‘Sleep’ checkbox is checked. This will automatically set the ‘Bin(sec)’ and ‘Step(sec)’ to the default values of ‘5’ and ‘2’, respectively.
10. In the ‘Function’ section, click ‘Spectrogram’. A figure containing the resulting EEG spectrogram (top of figure) and EMG line plot (bottom of figure) will appear. In the EEG spectrum, *blue* represents *no* EEG signal, *turquois* represents *weak* EEG signal, *green* represents *average* EEG signal, and *red* represents *strong* EEG signal. In the EMG line plot, low EMG values occur when the mouse is stationary (or sleeping), whereas high EMG values occur when the mouse is moving (awake)
  * If the EEG signal looks “blank” (mostly blue), try decreasing the ‘Clim’ value in the ‘Figures display’ section of the GUI (e.g. 1, 0.5, 0.2, 0.15) and clicking anywhere on the spectrogram window. The EEG spectrum will update with a new colormap of the signal strength. As you navigate the GUI and continue analyzing the data, the EEG spectrum may reset to the default value of 2 and appear “blank” again. Re-type the ‘Clim’ value you chose earlier and click anywhere on the spectrogram figure again
  * If the EEG looks noisy at 60 Hz, try clicking the ‘notch’ checkbox in the ‘Bandpass Filters (Hz)’ section of the GUI. Close the spectrogram figure and click ‘Spectrogram’ again.
  * If the EMG looks noisy, try filtering the EMG range in the ‘Bandpass Filters (Hz)’ section of the GUI. For the lower range of the EMG filter, do not enter a value larger than ‘30’. The upper range of the EMG filter should not be changed. Close the spectrogram figure and click ‘Spectrogram’ again.
  ![EEG Spectrogram](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/edfEEG2024.png)
  **Figure 4.** *An example of the EEG spectrogram and EMG line plot that generates after clicking 'Spectrogram'.*
11. In the ‘Function’ section of the GUI, click ‘Detect events’. The script will automatically assign sleep state scores based on the EEG spectrogram. A color-coded bar will appear above the EEG spectrogram. These are the following color-codes:
  * **Grey**: Wake (little to no EEG activity, high EMG activity)
  * **Orange**: NREM (high EEG activity (0.5 – 6 Hz), low EMG activity)
  * **Purple**: REM (high EEG activity (6 – 9 Hz), low EMG activity)
  ![Detect events](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/detect-events.png)
  **Figure 5.** *A color-coded sleep state scoring bar will appear above the spectrogram after clicking 'Detect events'.*
12. To zoom in on the EEG spectrogram (and EMG line plot), set a 10-minute time range in the ‘Figures display’ section of the GUI. For example, if the ‘Start(min)’ and ‘End (min)’ is set to ‘0’ and ‘60’, then set the ‘Figures display: Time’ to ‘0’ and ‘10’ to zoom in on the first 10 minutes. If the ‘Start(min)’ and ‘End (min)’ is set to ‘120’ and ‘180’, then set the ‘Figures display: Time’ to ‘120’ and ‘130’ to zoom in on the first 10 minutes.
  * If you would like, you can zoom in to a smaller time range (e.g. 5-minute time range)
  * To shift to the next 10 minutes of the figure, click the arrow buttons (‘<’ and ‘>’) in the ‘Figures display’ section of the GUI
  * To reset the figure back to the default 60 minute range, click the ‘reset’ button in the ‘Figures display’ section of the GUI
  ![Zoomed-in spectrogram](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/spectrogram-zoom.png)
  **Figure 6.** *A zoomed view of the first 10-minutes of data.*
13. The automated sleep state scoring done with the ‘Detect events’ button will likely not be 100% accurate. To fix this, check the ‘Manual-score’ checkbox in the ‘Function’ section of the GUI
14. The green ‘Mark’ button in the ‘Manual scoring’ section of the GUI will activate. Select the sleep-state you would like to manually score, then press ‘Mark’. Hover your cursor over the color-coded bar in spectrogram figure. You’ll notice the cursor is now a crosshair (‘+’) shape. Click on the color-coded bar at the boundaries of the sleep state period you would like to manually score. You must click on the start-to-end (or end-to-start) of the sleep state period (total of **two clicks**, not click-and-drag).
  * **Note:** When you are manually scoring, make sure you are clicking directly on the color-coded bar. Clicking elsewhere may incorrectly score sleep states
  * If any minor errors are made during manual scoring, try manually re-scoring the error. There is no “undo” function in the script.
  * If any major errors are made during manual scoring, click ‘Detect events’ in the GUI again and restart the manual scoring
  ![Manual scoring](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/manual-scoring.png)
  **Figure 7.** *An example of the manual scoring cursor (circled in red). The color-coded bar is the area where you should click while manually scoring sleep states.*
15. As you manually score, the ‘Command Window’ in the MATLAB program will output the updated ‘Wake/NREM/REM’ times (in minutes)
16.	Once you are done scoring the entire 60-minute time window, remember to click the ‘reset’ button in the ‘Figures display’ section of the GUI. Double-check that the sleep state scoring looks accurate.
17. In the top toolbar of the figure window, click ‘File > Save’. By default, the save location is inside the script folder. Do not save inside this folder to prevent the code from breaking. Locate the folder where the ‘.edf’ file was saved. Save the file with a consistent  naming structure such as: **ANIMAL-ID_FILE-NUMBER_START-END-TIME** (e.g. ‘K168-2_09_0-60min’)
18. In the ‘File’ section of the GUI, click ‘Save Result’. The ‘Command Window’ in the MATLAB program will output that the ‘.mat’ file was successfully saved in the folder you selected in the previous step.
  * In addition to a ‘.mat’ file, a ‘.txt’ file with the same naming convention is also saved, which contains information such as the number of sleep epochs, the times of each sleep epoch, and the total times of each sleep epoch
  ![.txt file](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/analyzed-txtfile.png)
  **Figure 8.** *An example of the '.txt' file generated after clicking 'Save Data'.*
19. To analyze the next hour within the same file, click the ‘>’ (right arrow) button in the ‘Process time window’ section of the GUI. The ‘Start(min)’ and ‘End(min)’ values should both increase by ‘60’
20. Click the ‘View Data’ button in the ‘File’ section of the GUI
  * If you forget to press this button, you’ll see that the spectrogram is the same as the previous time period you just finished analyzing
21. Click the ‘Spectrogram’ button in the GUI (refer to step 11 on page 4)

### Re-scoring previously scored time windows

1. If you would like to re-score a previously scored time window, click the ‘Open File’ button in the top of the GUI window. Select the ‘.mat’ file you would like to re-score. The scored spectrogram figure will appear in a new window, where you can view and edit any previous sleep/seizure state scoring
2. Once you are done re-scoring, be sure to click the ‘Save Data’ button in the GUI to overwrite your previous scoring


## Troubleshooting

### GUI is larger than my screen

* If the GUI window is larger than your screen and isn’t entirely visible, increase your monitor resolution
  * For Windows (Windows 11 and higher):
    1. Click the Windows icon (at bottom left of taskbar or on keyboard)
    2. Click on 'Settings' (gear icon)
    3. Click on 'System' > 'Display'
    4. Under 'Scale and layout, Change the size of text, apps, and other items' select '100%' from the dropdown menu
  * For macOS (Sonoma version 14 and higher):
    1. Go to 'System Settings' and search for 'Screen resolution'
    2. Scroll down and click on 'Advanced...'
    3. Enable 'Show resolutions as a list'
    4. Click 'Done'
    5. Select a resolution larger than the default resolution (e.g. if the default is '1512 x 982', select '1800 x 1169')
    ![GUI larger than screen](https://raw.githubusercontent.com/thepenglab/edfEEG2024/master/images/gui-larger.png)
    **Figure 9.** *An example of the GUI window being larger than the screen in macOS. Note how the buttons normally seen in the 'File' section of the GUI are missing here.*