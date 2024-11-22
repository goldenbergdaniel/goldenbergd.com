import "./style.css"
import { setupCounter } from "./counter.ts"

let counter = document.querySelector<HTMLButtonElement>("#counter")!
setupCounter(counter)
