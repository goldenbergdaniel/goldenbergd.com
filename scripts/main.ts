// Just leaving this here for future reference

function SetupCounter(element: HTMLButtonElement)
{
  let counter = 0
  
  function setCounter(count: number)
  {
    counter = count
    element.innerHTML = `count is ${counter}`
  }

  element.addEventListener("click", () => setCounter(counter + 1))
  setCounter(0)
}

let counter = document.querySelector<HTMLButtonElement>("#counter")!
if (counter)
{
  SetupCounter(counter)
}
