#!/bin/bash

while true; do

    # Read CPU package temperature sensors and record the values individually.
    # The values stored in cpuOut are floating point and need to be converted.
    cpuOut0=`sensors | awk -F'Package id 0: .[-+]|°C.*' '{print $2}'`
    cpuOut1=`sensors | awk -F'Package id 1: .[-+]|°C.*' '{print $2}'`

    # Write the reading for CPU 0 to cpuTemp0 and convert to int.
    cpuTemp0=`echo $cpuOut0 | bc`
    printf -v cpuTemp0 %.0f "$cpuTemp0" # Convert to int

    # Write the reading for CPU 0 to cpuTemp0 and convert to int.
    cpuTemp1=`echo $cpuOut1 | bc`
    printf -v cpuTemp1 %.0f "$cpuTemp1" # Convert to int

    # Used to test output. COMMENT OUT for released version
    #echo CPU 0: $cpuTemp0 C
    #echo CPU 1: $cpuTemp1 C

    # Identify highest temperature CPU and set as thje controlling temperature.
    if [ $cpuTemp0 -gt $cpuTemp1 ]
    then
        cpuTempCont=$cpuTemp0
    else
        cpuTempCont=$cpuTemp1
    fi

    # Calculate the duty cycle as a value between 0-255 and convert to hex. This
    # function is set to run the fans at a minimum of 10% up to 30C. After this point
    # the duty cycle ramps till CPU temp reaches 80C. After 80C, the fans run
    # at 100%.
    if [ $cpuTempCont -gt 85 ] # 80C or greater fan speed
    then
        pwm=255
        printf -v hex %x $pwm

    elif [ $cpuTempCont -le 85 ] && [ $cpuTempCont -gt 55 ] # Fan speed between 55-85C
    then
        pwm=$((((593*cpuTempCont)-24933)/100))
        printf -v hex %x $pwm

    elif [ $cpuTempCont -le 55 ] && [ $cpuTempCont -gt 35 ] # Fan speed between 35-55C
    then
        pwm=$((((320*cpuTempCont)-9900)/100))
        printf -v hex %x $pwm

    else # Fan speed under 35C
        pwm=13
        printf -v hex %x $pwm
    fi

    # Used to test output. COMMENT OUT for released version
    #echo CPU Control: $cpuTempCont C
    #echo PWM: $pwm
    #echo Hex: 0x$hex

    # Command fans to set duty cycle by passing $hex.
    ipmitool raw 0x3a 0x07 0xff 0x$hex 0x01
    #sleep .01s

done
