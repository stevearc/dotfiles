return function(telescope)
  telescope.setup({
    defaults = {
      winblend = 10,
      file_ignore_patterns = {
        ".*%.png$",
        ".*%.jpg$",
        ".*%.jpeg$",
        ".*%.gif$",
        ".*%.wav$",
        ".*%.aiff$",
        ".*%.dll$",
        ".*%.pdb$",
        ".*%.mdb$",
        ".*%.so$",
        ".*%.swp$",
        ".*%.zip$",
        ".*%.gz$",
        ".*%.bz2$",
        ".*%.meta",
        ".*%.cache",
        ".*/%.git/",
      },
    },
    extensions = {
      gkeep = {
        find_method = "title",
      },
      aerial = {},
    },
  })

  if not stevearc._find_files_impl then
    stevearc._find_files_impl = function(opts)
      opts = vim.tbl_deep_extend("keep", opts or {}, {
        previewer = false,
      })
      require("telescope.builtin").find_files(opts)
    end
  end
end
