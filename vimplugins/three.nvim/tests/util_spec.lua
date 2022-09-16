local util = require("three.util")

describe("util", function()
  describe("get_unique_names", function()
    before_each(function()
      util.sep = "/"
    end)

    it("leaves unique names alone", function()
      local ret = util.get_unique_names({ "/foo", "/foo/bar", "/foo/baz" })
      assert.are.same({ "/foo", "bar", "baz" }, ret)
    end)

    it("deduplicates files with the same name", function()
      local ret = util.get_unique_names({ "/foo/bar", "/baz/bar" })
      assert.are.same({ "/foo/bar", "/baz/bar" }, ret)
    end)

    it("deduplicates multiple files with the same name", function()
      local ret = util.get_unique_names({ "/a/foo/bar", "/b/foo/bar", "/c/foo/bar" })
      assert.are.same({ "/a/foo/bar", "/b/foo/bar", "/c/foo/bar" }, ret)
    end)

    it("uses full name to deduplicate if necessary", function()
      local ret = util.get_unique_names({ "/foo/bar", "foo/bar" })
      assert.are.same({ "/foo/bar", "foo/bar" }, ret)
    end)

    it("deduplicates names that share a long path", function()
      local ret = util.get_unique_names({ "/a/foo/bar/baz", "/b/foo/bar/baz" })
      assert.are.same({ "/a/foo/bar/baz", "/b/foo/bar/baz" }, ret)
    end)

    it("allows fully-duplicated names to have the same short name", function()
      local ret = util.get_unique_names({ "/foo/bar", "/foo/bar" })
      assert.are.same({ "bar", "bar" }, ret)
    end)
  end)
end)
