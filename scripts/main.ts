import { setupCounter } from "./counter.ts"

let counter = document.querySelector<HTMLButtonElement>("#counter")!
if (counter)
{
  setupCounter(counter)
}
