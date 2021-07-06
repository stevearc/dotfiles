local config = {}

local function prettier(parser)
  local parsearg = parser and string.format("--parser %s", parser) or ""
  local cmd = string.format("prettier %s --stdin-filepath '${INPUT}'", parsearg)
  return {
    formatCommand = cmd,
    formatStdin = true,
  }
end

config.sh = {
  {
    lintCommand = "shellcheck -f gcc -x",
    lintFormats = {
      "%f:%l:%c: %trror: %m",
      "%f:%l:%c: %tarning: %m",
      "%f:%l:%c: %tote: %m",
    },
    formatCommand = "shfmt -ci -i 2 -s -bn",
    formatStdin = true,
  },
}

config.python = {
  {
    lintCommand = "flake8 --stdin-display-name '${INPUT}' -",
    lintStdin = true,
    lintFormats = { "%f:%l:%c: %m" },
  },
  {
    lintCommand = "mypy --show-column-numbers",
    lintFormats = {
      "%f:%l:%c: %trror: %m",
      "%f:%l:%c: %tarning: %m",
      "%f:%l:%c: %tote: %m",
    },
  },
  {
    formatCommand = "isort - --quiet",
    formatStdin = true,
  },
  {
    formatCommand = "black -q -",
    formatStdin = true,
  },
}

config.yaml = { {
  lintCommand = "yamllint -f parsable -",
  lintStdin = true,
} }

config.rst = {
  {
    formatCommand = "pandoc -f rst -t rst -s --columns=79",
  },
  {
    lintCommand = "rst-lint",
    lintFormats = {
      "%tNFO %f:%l %m",
      "%tARNING %f:%l %m",
      "%tRROR %f:%l %m",
      "%tEVERE %f:%l %m",
    },
  },
}

config.md = { {
  formatCommand = "pandoc -f markdown -t gfm -sp --tab-stop=2",
} }

config.vim = {
  {
    lintCommand = "vint --enable-neovim -",
    lintStdin = true,
    lintFormats = {
      "%f:%l:%c: %m",
    },
  },
}

config.lua = {
  {
    formatCommand = "stylua -",
    formatStdin = true,
    rootMarkers = {
      "stylua.toml",
      ".stylua.toml",
    },
  },
  {
    lintCommand = "luacheck --globals vim --filename '${INPUT}' --formatter plain -",
    lintStdin = true,
    lintFormats = {
      "%f:%l:%c: %m",
    },
  },
}

config.css = { prettier("css") }
config.html = { prettier("html") }
config.json = { prettier("json") }

config.javascript = { prettier() }
config.javascriptreact = config.javascript
config["javascript.jsx"] = config.javascript

config.php = { {
  formatCmd = "hackfmt",
  formatStdin = true,
} }

config.xml = { {
  formatCommand = "xmllint --format -",
  formatStdin = true,
} }

config.supercollider = { {
  formatCommand = "sed -e 's/ *$//' -e 's/\t/  /g'",
  formatStdin = true,
} }

return config
