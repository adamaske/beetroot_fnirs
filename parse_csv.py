import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


def parse_hrf_csv(file_path):
    """
    Parses a single HRF data CSV file (HbO, HbR, or HbT) into two separate 
    NumPy arrays: one for Time Series (mean HRF) and one for Standard Deviation.

    Args:
        file_path (str): The full path to the HRF CSV file. 
                         (e.g., 'before_hrf_hbo.csv')

    Returns:
        tuple: (ts_array, std_array)
            - ts_array (numpy.ndarray): The mean HRF time series data.
            - std_array (numpy.ndarray): The standard deviation data.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Error: File not found at {file_path}")

    # 1. Read the CSV into a pandas DataFrame
    df = pd.read_csv(file_path)

    # 2. Filter columns to separate Time Series (TS) and Standard Deviation (STD)
    # The 'like' argument uses the naming convention established in MATLAB
    df_ts = df.filter(like='ts_ch')
    df_std = df.filter(like='std_ch')

    # 3. Convert the resulting DataFrames to NumPy arrays
    ts_array = df_ts.values
    std_array = df_std.values

    print(f"Successfully parsed {os.path.basename(file_path)}. TS Shape: {ts_array.shape}, STD Shape: {std_array.shape}")
    
    return np.array(ts_array), np.array(std_array)

def disp_avg_HRF(filepath, title='HRF Data', filepath_fig=None, show=True, y_lim=None):
    ts, std = parse_hrf_csv(filepath)
    
    # 1. Correct: Average across channels (columns, axis=1) to get the mean time course.
    ts_mean = np.mean(ts, axis=1) 
    # Use the standard deviation of the mean (SEM) or just the mean of the STD across channels
    std_avg_across_channels = np.mean(std, axis=1) 

    # 2. Correct: Create time vector from 0 to 20 seconds
    # ts.shape[0] is the number of time points (rows)
    num_timepoints = ts.shape[0]
    t = np.linspace(0, 20, num=num_timepoints)
    
    # Define colorblind-safe, high-contrast colors
    MEAN_COLOR = '#000000'    # Pure Black (Excellent contrast for line)
    FILL_COLOR = '#A6CEE3'    # Light, desaturated cyan/blue (Distinguishable from black, but soft)
    
    plt.figure(figsize=(8, 5))
    
    # Plot Standard Deviation as shading (Fill area is critical for error)
    plt.fill_between(
        t, 
        ts_mean - std_avg_across_channels, 
        ts_mean + std_avg_across_channels, 
        color=FILL_COLOR, 
        alpha=0.6, 
        edgecolor='none', # Remove border for cleaner look
        label='Mean $\pm$ 1 SD'
    )
    
    # Plot Mean HRF line (High contrast line that won't be confused with the fill)
    plt.plot(
        t, 
        ts_mean, 
        color=MEAN_COLOR, 
        linewidth=2.5, 
        zorder=3, # Ensures the line is drawn on top of the fill
        label='Mean HRF'
    )
     # --- MANUAL Y-AXIS CONTROL ---
    if y_lim is not None:
        plt.ylim(y_lim) 
    # Enhance readability for scientific articles
    plt.axhline(0, color='gray', linestyle='--', linewidth=0.8) # Add a zero line
    
    # Labels and Title
    plt.title(title, fontsize=14)
    plt.xlabel('Time (s)', fontsize=14)
    plt.ylabel('Concentration Change ($\mu$M)', fontsize=14)
    plt.legend(frameon=False, fontsize=14) # Remove legend box for cleaner look
    plt.tick_params(direction='in') # Inward tick marks
    plt.tight_layout() # Adjust layout to prevent clipping
    plt.savefig(filepath_fig, dpi=300) if filepath_fig else None
    if show:
        plt.show()


files = ['before_hrf_hbo.csv', 'before_hrf_hbr.csv', 'before_hrf_hbt.csv',
         'after_hrf_hbo.csv', 'after_hrf_hbr.csv', 'after_hrf_hbt.csv']
names = ['Before NO - HbO', 'Before NO - HbR', 'Before NO - HbT',
         'After NO - HbO', 'After NO - HbR', 'After NO - HbT']
UNIVERSAL_Y_SCALE = (-4.5e-05, 4.5e-05) 
for file, name in zip(files, names):
    figure_filename = file.replace('.csv', '.png')
    print(f"Processing {file} and saving figure as {figure_filename}")
    disp_avg_HRF(file, title=name, filepath_fig=figure_filename, show=True, y_lim=UNIVERSAL_Y_SCALE)
    
# --- Example Call ---
# You would need to ensure 'before_hrf_hbo.csv' exists in the current directory
disp_avg_HRF('before_hrf_hbo.csv', title='Before NO - HbO HRF')

exit()

def load_nirs_hrf_data(base_path='./'):
    """
    Reads all HbO, HbR, and HbT HRF data from the 'before' and 'after'
    conditions located in the same directory as the script.

    Args:
        base_path (str): The directory where the CSV files are located. 
                         Defaults to './' (the current directory).

    Returns:
        dict: A nested dictionary structured as: 
              {'condition': {'species': pandas.DataFrame}}
    """
    
    # Define the conditions and hemoglobin species based on your filenames
    conditions = ['before', 'after']
    species = ['hbo', 'hbr', 'hbt']
    
    # Initialize the main dictionary
    hrf_data = {}
    
    # Get the absolute path to confirm where the script is looking
    print(f"Searching for files in the current directory: {os.path.abspath(base_path)}")

    for condition in conditions:
        hrf_data[condition] = {}
        
        for sp in species:
            # Construct the expected filename, e.g., 'before_hrf_hbo.csv'
            filename = f'{condition}_hrf_{sp}.csv'
            full_path = os.path.join(base_path, filename)

            try:
                # pandas.read_csv reads the data, using the first row as the header
                df = pd.read_csv(full_path)
                
                # Store the DataFrame
                hrf_data[condition][sp] = df
                print(f"Successfully loaded: {filename}")
                
            except FileNotFoundError:
                print(f"Warning: File not found at {full_path}. Please confirm the file name and location.")
            except Exception as e:
                print(f"Error loading {filename}: {e}")
                
    return hrf_data

# -----------------------------------------------------------
# --- Main Execution ---
# -----------------------------------------------------------

# 1. Load all data from the current directory
nirs_data = load_nirs_hrf_data()

# 2. Example: Access the 'before' HbO data and separate the TS and STD
if nirs_data and 'before' in nirs_data and 'hbo' in nirs_data['before']:
    before_hbo_df = nirs_data['before']['hbo']

    print("\n--- Data Preview (before_hrf_hbo.csv) ---")
    print(before_hbo_df.head())

    # Filter columns to separate Time Series (ts) from Standard Deviation (std)
    # The 'ts_chN' columns contain the mean HRF data
    ts_data = before_hbo_df.filter(like='ts_ch')
    
    # The 'std_chN' columns contain the standard deviation for error bars
    std_data = before_hbo_df.filter(like='std_ch')

    print(f"\nTime Series Columns (HRF Mean): {ts_data.shape[1]}")
    print(f"Standard Deviation Columns (HRF Std): {std_data.shape[1]}")

df_hbo_after = nirs_data['after']['hbo']

df_hbo_after_ts = df_hbo_after.filter(like='ts_ch')
df_hbo_after_std = df_hbo_after.filter(like='std_ch')


hbo_after_ts = np.array(df_hbo_after_ts.values ).T
hbo_after_std = np.array(df_hbo_after_std.values ).T

hbo_after_ts_mean = np.mean(hbo_after_ts, axis=0)
hbo_after_std_mean = np.mean(hbo_after_std, axis=0)

plt.plot(hbo_after_ts_mean, color='blue', label='Mean HRF')
plt.plot(hbo_after_std_mean, color='black', label='Std Dev')
plt.title('HbO Time Series HRF ')
plt.xlabel('Time Points')
plt.legend()
plt.show()