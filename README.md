# wxsat-scheduler
Shell scripts for receiving NOAA weather satellites via Raspberry Pi.

Required software:
1. rtl_sdr (containing rtl_fm) for recording raw IQ data from RTLSDR dongles
2. sox (for conversion to 11025 Hz sample rate and output WAV file)
3. wxtoimg (including wxmap for creating map overlay)
