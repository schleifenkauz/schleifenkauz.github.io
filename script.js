const queryStr = window.location.search;
const urlParams = new URLSearchParams(queryStr);
const site = urlParams.get('q') ?? 'home';

document.onreadystatechange = function () {
    if (document.readyState == 'complete') {
        const contentEl = document.getElementById('content');
        if (site == 'all-audio') {
            include(contentEl, 'acousmatic-music');
            include(contentEl, 'piano-recordings');
        } else {
            include(contentEl, site);
        }
    }
};

function include(element, site) {
    const req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (this.readyState == 4) {
            console.log(this.status);
            if (this.status == 200) {
                element.innerHTML += this.responseText;
            }
            if (this.status == 404) {element.innerHTML = "Page not found.";}
        }
    }
    const url =  `${window.location.origin}/sites/${site}.html`;
    req.open("GET", url, true);
    req.send();
}


function show_texts() {

}