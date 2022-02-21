vim.cmd([[command! PoreVersion lua require("pore").print_version()]])
vim.cmd([[command! PoreInstall lua require("pore").install_from_source()]])
vim.cmd([[command! PoreTest lua require("pore").test()]])
