return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("telescope").setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
        },
      })

      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files,
        { desc = "Find files" })

      vim.keymap.set("n", "<leader>fg", builtin.live_grep,
        { desc = "Search in files" })

      vim.keymap.set("n", "<leader>fb", builtin.buffers,
        { desc = "Find buffers" })

      vim.keymap.set("n", "<leader>fh", builtin.help_tags,
        { desc = "Help tags" })
    end,
  },
}
