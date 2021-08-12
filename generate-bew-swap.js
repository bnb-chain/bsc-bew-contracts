const program = require("commander");
const fs = require("fs");
const nunjucks = require("nunjucks");

program.version("0.0.1");
program.option(
    "-t, --template <template>",
    "bsc swap template file",
    "./contracts/BewSwapImplement.template"
);

program.option(
    "-o, --output <output-file>",
    "BSCSwapAgentImpl.sol",
    "./contracts/BewSwapImplement.sol"
)

program.option("--mock <mock>",
    "if use mock",
    false
);

program.parse(process.argv);

let data = {
  mock: program.mock,
};

if (program.mock === "true") {
  data = {
    mock: program.mock,
  };
}


const templateString = fs.readFileSync(program.template).toString();
const resultString = nunjucks.renderString(templateString, data);
fs.writeFileSync(program.output, resultString);
console.log("Bew swap file updated.");
