const queryStr = window.location.search;
const urlParams = new URLSearchParams(queryStr);
const site = urlParams.get('q') ?? 'home';

document.onreadystatechange = function () {
    if (document.readyState == 'complete') {
        const contentEl = document.getElementById('content');
        include(contentEl, site);
    }
};

function include(element, site) {
    const req = new XMLHttpRequest();
    req.onreadystatechange = function () {
        if (this.readyState == 4) {
            console.log(this.status);
            if (this.status == 200) {
                element.innerHTML += this.responseText;
            }
            if (this.status == 404) { element.innerHTML = "Page not found."; }
        }
    }
    const url = `${window.location.origin}/sites/${site}.html`;
    req.open("GET", url, true);
    req.send();
}

function copyCode(button) {
    const codeBlock = button.nextElementSibling.innerText;
    navigator.clipboard.writeText(codeBlock).then(() => {
        button.textContent = "Copied!";
        setTimeout(() => (button.textContent = "Copy"), 1500);
    });
}

function isValidEmail(email) {
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return regex.test(email);
}

let cachedEmail = null

async function requestFullTrack(btn, trackName) {
    const emailField = btn.previousElementSibling;
    if (btn.textContent == "Download full track") {
        console.log("Making ", emailField, "visible");
        emailField.style.display = "block";
        if (cachedEmail != null) {
            emailField.value = cachedEmail;
        }
        btn.textContent = "Confirm email"
        let previewDisclaimer = btn.nextElementSibling
        previewDisclaimer.style.display = "none"
    } else if (btn.textContent == "Confirm email") {
        let statusText = emailField.previousElementSibling;
        if (!isValidEmail(emailField.value)) {
            alert("Invalid email")
            return
        }
        cachedEmail = emailField.value

        let data = new FormData()
        data.append("email", emailField.value)
        data.append("message", trackName)
        let response = await fetch("https://formspree.io/f/mqadkbqw", {
            method: "POST",
            body: data,
            headers: { 'Accept': 'application/json' }
        });

        if (response.ok) {
            statusText.style.display = "block"
            emailField.value = ""
            emailField.style.display = "none"
            btn.style.display = "none"
        } else {
            alert("There was a problem submitting your form.")
        }
    }
}