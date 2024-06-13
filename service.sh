#!/system/bin/sh

function reloadAudioserver()
{
    # wait for system boot completion and audiosever boot up
    local i
    for i in `seq 1 5` ; do
        if [ "`getprop sys.boot_completed`" = "1"  -a  -n "`getprop init.svc.audioserver`" ]; then
            break
        fi
        sleep 1.3
    done

    if [ -n "`getprop init.svc.audioserver`" ]; then

        setprop ctl.restart audioserver
        sleep 0.2
        if [ "`getprop init.svc.audioserver`" != "running" ]; then
            # workaround for Android 12 old devices hanging up the audioserver after "setprop ctl.restart audioserver" is executed
            local pid="`getprop init.svc_debug_pid.audioserver`"
            if [ -n "$pid" ]; then
                kill -HUP $pid 1>"/dev/null" 2>&1
            fi
            for i in `seq 1 10` ; do
                sleep 0.2
                if [ "`getprop init.svc.audioserver`" = "running" ]; then
                    break
                elif [ $i -eq 10 ]; then
                    echo "audioserver reload failed!" 1>&2
                    return 1
                fi
            done
        fi
        return 0
        
    else
        echo "audioserver is not found!" 1>&2 
        return 1
    fi
}

function setResamplingParameters()
{
#  Workaround for recent Pixel Firmwares (not to reboot when resetprop'ing)
    resetprop --delete ro.audio.resampler.psd.enable_at_samplerate
    resetprop --delete ro.audio.resampler.psd.stopband
    resetprop --delete ro.audio.resampler.psd.halflength
    resetprop --delete ro.audio.resampler.psd.cutoff_percent
    resetprop --delete ro.audio.resampler.psd.tbwcheat
#  End of workaround
    
    resetprop ro.audio.resampler.psd.enable_at_samplerate 44100
    resetprop ro.audio.resampler.psd.stopband 179
    resetprop ro.audio.resampler.psd.halflength 520
    resetprop ro.audio.resampler.psd.cutoff_percent 94
    # Uncomment the following lines if you intend to replay only 96 kHz & 24 bits Hires. tracks
    # resetprop ro.audio.resampler.psd.enable_at_samplerate 96000
    # resetprop ro.audio.resampler.psd.cutoff_percent 44

    reloadAudioserver
}

setResamplingParameters 1>"/dev/null" 2>&1
