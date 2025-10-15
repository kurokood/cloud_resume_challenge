const GothicBackground = () => {
  return (
    <div className="fixed inset-0 -z-10 overflow-hidden">
      {/* Dark gradient base */}
      <div className="absolute inset-0 bg-gradient-to-b from-gothic-darker via-gothic-dark to-gothic-darker" />
      
      {/* Fog layers */}
      <div className="absolute inset-0 fog-animation opacity-30">
        <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-b from-transparent via-gothic-mist/20 to-transparent" />
      </div>
      
      <div className="absolute inset-0 fog-animation opacity-20" style={{ animationDelay: '5s', animationDuration: '25s' }}>
        <div className="absolute top-1/4 left-0 w-full h-3/4 bg-gradient-to-t from-transparent via-gothic-mist/30 to-transparent" />
      </div>
      
      {/* Subtle gothic pattern overlay */}
      <div 
        className="absolute inset-0 opacity-5"
        style={{
          backgroundImage: `radial-gradient(circle at 2px 2px, hsl(var(--gothic-silver)) 1px, transparent 0)`,
          backgroundSize: '40px 40px',
        }}
      />
      
      {/* Vignette effect */}
      <div className="absolute inset-0 bg-gradient-radial from-transparent via-transparent to-gothic-darker/80" />
    </div>
  );
};

export default GothicBackground;
