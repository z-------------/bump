import strutils
import options
import unittest

import bump

suite "bump":
  setup:
    let
      ver123 {.used.} = (major: 1, minor: 2, patch: 3)
      ver155 {.used.} = (major: 1, minor: 5, patch: 5)
      ver170 {.used.} = (major: 1, minor: 7, patch: 0)
      ver171 {.used.} = (major: 1, minor: 7, patch: 1)
      ver456 {.used.} = (major: 4, minor: 5, patch: 6)
      ver457 {.used.} = (major: 4, minor: 5, patch: 7)
      ver789 {.used.} = (major: 7, minor: 8, patch: 9)
      ver799 {.used.} = (major: 7, minor: 9, patch: 9)
      aList {.used.} = ""
      bList {.used.} = """
        v.1.2.3
        V.4.5.6
        v7.8.9
        V10.11.12
      """.unindent.strip
      cList {.used.} = """
        v.1.2.3
        4.5.6
        v7.8.9
        V10.11.12
        12.13.14
      """.unindent.strip
      crazy {.used.} = @[
        """version="1.2.3"""",
        """version      = "1.2.3"""",
        """version	 			 	= 	 		  "1.2.3"  """,
      ]

  test "parse version statement":
    for c in crazy:
      check ver123 == c.parseVersion.get

  test "substitute version into line with crazy spaces":
    for c in crazy:
      check ver123.withCrazySpaces(c) == c
    check ver123.withCrazySpaces("""version="4.5.6"""") == crazy[0]

  test "are we on the master branch":
    let
      isMaster = appearsToBeMasterBranch()
    check isMaster.isSome
    check isMaster.get

  test "all tags appear to start with v":
    check bList.allTagsAppearToStartWithV
    check not cList.allTagsAppearToStartWithV
    check not aList.allTagsAppearToStartWithV

  test "identify tags for arbitrary versions":
    let
      tagList = fetchTagList()
      isTagged {.used.} = ver170.taggedAs(tagList.get)
      notTagged {.used.} = ver155.taggedAs(tagList.get)
    check isTagged.isSome and isTagged.get == "1.7.0"
    check notTagged.isNone

  test "last tag in the tag list":
    expect ValueError:
      discard aList.lastTagInTheList
    check bList.lastTagInTheList == "V10.11.12"
    check cList.lastTagInTheList == "12.13.14"

  test "compose the right tag given strange input":
    let
      tagv171 {.used.} = composeTag(ver170, ver171, v = true, tags = aList)
      tag171 {.used.} = composeTag(ver170, ver171, v = false, tags = aList)
      tagv457 {.used.} = composeTag(ver456, ver457, tags = bList)
      tagv799 {.used.} = composeTag(ver789, ver799, tags = cList)
      tagv456 {.used.} = composeTag(ver123, ver456, tags = cList)
      tag457 {.used.} = composeTag(ver155, ver457, tags = cList)
      tagv155 {.used.} = composeTag(ver799, ver155, tags = bList)
    check tagv171.get == "v1.7.1"
    check tag171.get == "1.7.1"
    check tagv457.get == "V.4.5.7"
    check tagv799.get == "v7.9.9"
    check tagv456.get == "v.4.5.6"
    check tag457.get == "4.5.7"
    check tagv155.get == "V1.5.5"