#!/bin/bash
# D2GS 1.13d overflows in Fog.dll unless Windows reports XP.
wine reg add "HKCU\\Software\\Wine\\AppDefaults\\D2GS.exe" /v Version /t REG_SZ /d winxp /f
wine regedit /s d2gs.reg
exec wine D2GS.exe /nogui
