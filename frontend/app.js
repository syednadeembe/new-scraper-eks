function showLoader() {
  const loader = document.getElementById("loader");
  if (loader) loader.style.display = "block";
}

function hideLoader() {
  const loader = document.getElementById("loader");
  if (loader) loader.style.display = "none";
}

function searchNews() {
  const topic = document.getElementById("searchInput").value.trim();
  if (!topic) {
    alert("Please enter a topic to search!");
    return;
  }

  showLoader();
  fetch(`/search?topic=${encodeURIComponent(topic)}`)
    .then(response => {
      if (!response.ok) throw new Error(`Search failed: ${response.status}`);
      return response.json();
    })
    .then(data => {
      hideLoader();
      displayResults(data);
    })
    .catch(error => {
      console.error("Error fetching search results:", error);
      hideLoader();
      alert("Something went wrong. Please try again later.");
    });
}

function getHistory() {
  showLoader();
  fetch("/history")
    .then(response => {
      if (!response.ok) throw new Error(`History request failed: ${response.status}`);
      return response.json();
    })
    .then(data => {
      hideLoader();
      displayHistory(data);
    })
    .catch(error => {
      console.error("Error fetching history:", error);
      hideLoader();
      alert("Something went wrong. Please try again later.");
    });
}

function displayResults(data) {
  const resultsDiv = document.getElementById("results");
  resultsDiv.innerHTML = `<h2>Search Results (${data.source})</h2>`;

  if (data.results.length === 0) {
    resultsDiv.innerHTML += "<p>No articles found.</p>";
  } else {
    data.results.forEach(article => {
      resultsDiv.innerHTML += `
        <div class="news-card">
          <a href="${article.link}" target="_blank" rel="noopener noreferrer">${article.title}</a>
        </div>
      `;
    });
  }
}

function toggleInfo() {
  const infoDiv = document.getElementById("infoDetails");
  infoDiv.style.display = infoDiv.style.display === "none" ? "block" : "none";
}

function displayHistory(historyData) {
  const historyDiv = document.getElementById("history");
  historyDiv.innerHTML = "<h2>Search History</h2>";

  if (historyData.length === 0) {
    historyDiv.innerHTML += "<p>No previous searches found.</p>";
  } else {
    historyData.forEach(item => {
      historyDiv.innerHTML += `
        <p>🔹 ${item.topic} — <i>${new Date(item.created_at).toLocaleString()}</i></p>
      `;
    });
  }
}
