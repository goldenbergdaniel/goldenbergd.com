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

// Define an interface for keyword-color pairs
interface KeywordStyle
{
  keyword: string;
}

const COLOR = "#72abcc"

// Main function to highlight keywords
function highlightKeywordsInCode()
{
  // Define the keywords and their corresponding colors
  const keywords: KeywordStyle[] = [
    { keyword: "package"},
    { keyword: "import"},
    { keyword: "proc"},
    { keyword: "if"},
    { keyword: "for"},
    { keyword: "return"},
    { keyword: "#include"},
  ];

  // Get all code elements
  const codeElements = document.getElementsByTagName("code")

  // Process each code element
  Array.from(codeElements).forEach((codeElement) => {
    let content = codeElement.innerHTML;

    // Escape HTML special characters first to prevent XSS and breaking HTML
    // content = escapeHtml(content);

    // Split content into words while preserving whitespace and special characters
    const words = content.split(/(\s+|[{}()[\];,.!?:])/)

    // Process each word
    const highlightedContent = words.map((word) => {
      const matchedKeyword = keywords.find((kw) => 
        kw.keyword === word.trim() && 
        // Ensure it's a whole word (not part of another word)
        !/\w/.test(content[content.indexOf(word) - 1] || '') &&
        !/\w/.test(content[content.indexOf(word) + word.length] || '')
      )

      if (matchedKeyword)
      {
        return `<span style="color: ${COLOR}">${word}</span>`;
      }

      return word

    }).join('');

    // Update the code element with highlighted content
    codeElement.innerHTML = highlightedContent
  })
}

// Helper function to escape HTML special characters
// function escapeHtml(text: string): string
// {
//   const map: { [key: string]: string } = {
//     '&': '&amp;',
//     '<': '&lt;',
//     '>': '&gt;',
//     '"': '&quot;',
//     "'": '&#039;',
//   }

//   return text.replace(/[&<>"']/g, (m) => map[m])
// }

// Run the highlighting when the DOM is fully loaded
document.addEventListener('DOMContentLoaded', () => {
  highlightKeywordsInCode()
})
