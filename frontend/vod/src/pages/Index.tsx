import { useState } from 'react';
import VideoPlayer from '@/components/VideoPlayer';
import GothicBackground from '@/components/GothicBackground';
import RavenIcon from '@/components/RavenIcon';

const Index = () => {
  // ⚙️ EDITABLE VIDEO SOURCES - Update these URLs with your AWS S3 bucket URLs
  const [videoSources] = useState({
    hls: 'https://mybucket.s3.amazonaws.com/wednesday/trailer.m3u8',
    dash: 'https://mybucket.s3.amazonaws.com/wednesday/trailer.mpd'
  });

  return (
    <div className="relative min-h-screen flex flex-col">
      <GothicBackground />
      
      {/* Main content */}
      <main className="flex-1 flex flex-col items-center justify-center px-4 py-12 md:py-16 lg:py-20">
        {/* Raven icon */}
        <div className="mb-6 text-gothic-silver">
          <RavenIcon />
        </div>

        {/* Title section */}
        <header className="text-center mb-8 md:mb-12">
          <h1 className="font-playfair text-4xl md:text-5xl lg:text-6xl font-bold text-foreground mb-3 tracking-wide gothic-glow">
            Wednesday
          </h1>
          <p className="font-cinzel text-lg md:text-xl text-gothic-silver uppercase tracking-widest">
            Official Trailer
          </p>
        </header>

        {/* Video player */}
        <section className="w-full max-w-5xl mb-8 md:mb-12">
          <div className="relative rounded-lg overflow-hidden border-2 border-gothic-mist shadow-2xl">
            <VideoPlayer hlsUrl={videoSources.hls} dashUrl={videoSources.dash} />
          </div>
        </section>

        {/* Tagline */}
        <div className="text-center mb-12">
          <p className="font-playfair text-lg md:text-xl italic text-muted-foreground max-w-2xl mx-auto">
            "From the world of The Addams Family — Experience the darkness."
          </p>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-6 text-center border-t border-gothic-mist">
        <p className="font-cinzel text-sm text-muted-foreground tracking-wide">
          Hosted on AWS S3 | Powered by AWS Video on Demand
        </p>
      </footer>

      {/* Instructions comment for easy editing */}
      {/* 
        📝 TO UPDATE VIDEO SOURCES:
        
        Edit the videoSources object above (around line 8) with your AWS S3 URLs:
        
        hls: 'https://your-bucket.s3.amazonaws.com/path/to/video.m3u8'
        dash: 'https://your-bucket.s3.amazonaws.com/path/to/video.mpd'
        
        The page will automatically serve the correct format based on the user's device.
      */}
    </div>
  );
};

export default Index;
