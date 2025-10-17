# VM Optimization Tips for Ubuntu on VMware Fusion

## Video Playback Issues

Video lag/buffering in VMs is common due to hardware limitations. Here are solutions:

### VMware Fusion Settings (Mac Host)

1. **Display Settings**:
   - Virtual Machine → Settings → Display
   - ✅ Enable "Accelerate 3D Graphics"
   - Set "Graphics Memory" to 2GB or higher
   - ✅ Enable "Use full resolution for Retina display"

2. **Processors & Memory**:
   - Increase RAM to at least 4-8GB
   - Allocate 2-4 CPU cores
   - Enable "Virtualize Intel VT-x/EPT or AMD-V/RVI"

3. **Sound**:
   - Ensure sound card is enabled
   - Use "Auto detect" for output device

### Software Optimizations

1. **Installed Codecs**:
   ```bash
   sudo apt install -y ubuntu-restricted-extras libavcodec-extra ffmpeg
   ```

2. **Browser Tips**:
   - Use Chromium instead of Firefox for better video performance
   - Install: `sudo snap install chromium`
   - Lower video quality (720p or 480p instead of 1080p)
   - Use YouTube in 480p or 720p for smooth playback

3. **Firefox Hardware Acceleration** (if using Firefox):
   - Go to `about:config`
   - Set `media.hardware-video-decoding.enabled` = true
   - Set `gfx.webrender.all` = true
   - Restart Firefox

### General Performance Tips

1. **Disable visual effects**:
   ```bash
   # Install GNOME Tweaks
   sudo apt install gnome-tweaks
   # Then disable animations in Tweaks → General → Animations
   ```

2. **Close unnecessary apps** when watching video

3. **Use lightweight apps**:
   - Chromium instead of Firefox
   - Simple video players like VLC or MPV

4. **Check resource usage**:
   ```bash
   btop  # or htop to see CPU/RAM usage
   ```

### Expected Limitations

- VMs will always have some performance overhead
- 4K video may not play smoothly
- Multiple videos or heavy multitasking may cause lag
- Hardware acceleration is limited in virtualized environments

### Alternative: Native Installation

For best performance, consider dual-booting or installing Ubuntu natively on hardware. VMs are great for development but have inherent performance limitations for graphics-intensive tasks.
