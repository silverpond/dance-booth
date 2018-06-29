export const danceState = {
  mode:     "idle",
  capturer: undefined,
  frames:   []
}


const countTitle = document.getElementById("count-title");
const count      = document.getElementById("count");


const countDown = (k, f) => {
  if( k > 0 ){
    count.innerHTML = k.toString();
    window.setTimeout( () => countDown(k - 1, f), 1000 );
  } else {
    f();
  }
}


export const startReadyCountdown = () => {
  danceState.mode   = "readying";
  danceState.frames = [];

  const readyTime = 3;

  countTitle.innerHTML = "Get ready to dance in ...";
  countDown(readyTime, startDanceCountdown);
}


export const startDanceCountdown = () => {
  danceState.mode = "dancing";
  danceState.capturers.forEach(c => c.startRecording());

  const danceTime = 10;
  countTitle.innerHTML = "Dance!";

  countDown(danceTime, wrapUpDance);
}


export const wrapUpDance = () => {
  danceState.capturers.forEach( (c, i) => c.stopRecording( () => {
    const blob     = c.getBlob();
    const formData = new FormData();

    const filename = i == 0 ? "Video" : "Dance";

    formData.append("image", blob, filename + ".webm");
    
    fetch("/do-upload", {
      method: "POST",
      body: formData,
    }).then( (resp) => {
      console.log("Got response: ", resp);
    });
  }));

  // Save the json too!
  const formData = new FormData();
  const json     = JSON.stringify(danceState.frames);
  const blob     = new Blob([json], {type : 'application/json'});

  formData.append("json", blob, "Poses.json");

  fetch("/do-upload", {
    method: "POST",
    body: formData,
  }).then( (resp) => {
    console.log("Got response: ", resp);
  });

  danceState.mode   = "idle";
  danceState.frames = [];

  countTitle.innerHTML = "";
  count.innerHTML      = "";
  console.log("The dance is all done!");
}
