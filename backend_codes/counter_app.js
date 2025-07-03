<div id="visitor-count">You are visitor number:<br><span id="visitor-number">Loading...</span></div>

<script>
  async function updateVisitorCount() {
    try {
      const response = await fetch('https://ckl3yj2h06.execute-api.us-east-1.amazonaws.com/VisitorCounter');
      const data = await response.json();
      if (data.count !== undefined) {
        document.getElementById('visitor-number').textContent = data.count;
      } else {
        document.getElementById('visitor-number').textContent = 'Unavailable';
      }
    } catch (error) {
      console.error('Error fetching visitor count:', error);
      document.getElementById('visitor-number').textContent = 'Error';
    }
  }

  updateVisitorCount();
</script>