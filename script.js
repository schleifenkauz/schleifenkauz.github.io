const queryStr = window.location.search;
const urlParams = new URLSearchParams(queryStr);
const site = urlParams.get('q') ?? 'about';

document.onreadystatechange = function () {
    if (document.readyState == 'complete') {
        console.log(document.getElementsByName("subsite"));
        [...document.getElementsByTagName('subsite')].forEach(function (el) {
            if (el.id != site && el.remove !== null)  {
                console.log(`Removing ${el}`);
                el.remove();
            }
        });
    }
};


function show_texts() {

}