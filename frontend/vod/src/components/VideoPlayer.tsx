import { useEffect, useRef } from 'react';
import videojs from 'video.js';
import 'video.js/dist/video-js.css';

interface VideoPlayerProps {
  hlsUrl: string;
  dashUrl: string;
}

const VideoPlayer = ({ hlsUrl, dashUrl }: VideoPlayerProps) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const playerRef = useRef<any>(null);

  useEffect(() => {
    // Ensure Video.js player is only initialized once
    if (!playerRef.current && videoRef.current) {
      const videoElement = videoRef.current;

      // Detect device/browser and choose appropriate format
      const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
      const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
      const useHLS = isSafari || isIOS;

      const videoSource = useHLS ? hlsUrl : dashUrl;
      const videoType = useHLS ? 'application/x-mpegURL' : 'application/dash+xml';

      playerRef.current = videojs(videoElement, {
        controls: true,
        autoplay: false,
        preload: 'auto',
        fluid: true,
        responsive: true,
        aspectRatio: '16:9',
        sources: [
          {
            src: videoSource,
            type: videoType,
          },
        ],
      });

      console.log(`Loaded ${useHLS ? 'HLS' : 'DASH'} stream for device`);
    }

    // Cleanup on unmount
    return () => {
      if (playerRef.current) {
        playerRef.current.dispose();
        playerRef.current = null;
      }
    };
  }, [hlsUrl, dashUrl]);

  return (
    <div className="w-full max-w-5xl mx-auto" data-vjs-player>
      <video
        ref={videoRef}
        className="video-js vjs-big-play-centered vjs-theme-fantasy"
        playsInline
      />
    </div>
  );
};

export default VideoPlayer;
