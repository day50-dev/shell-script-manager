ursh.dev is a repository for a new concept called "urshies". Urshies (sigular Urshi) is a replacement for "curl <url> | bash" to "packages" like for uv, npx, go, and other tools out there.

However, unlike say dockerhub, ursh.dev is an aggregator that stores mostly meta data. An urshi is comprised of a structure either for llm, human, or classical tool ingestion of the following form:

```
    name:       The name of the tool
    description:    What it's supposed to do
    url:        Where it lives (reputations are determined mostly by this. For instance, github.com/microsoft is reputable while shady-url.ru is not)
    homepage:   url for more information
    readme:     can be blank
    license:    can be blank
    checksum:   The last known checksum
    date:       iso 8661 date of the last check
    compliances:
        ( this is list such as HIPPA, SOC-2 or other certifications the source page attests to )
    privileges:
        files:      files it wants to access
            read:   files to read
            write:  files to write
        network:    network resources it talks to (urls basically)
            get:    the urls it pulls stuff from
            put:    the urls it puts stuff to (including if the urls it gets stuff from are programmatic, curl "somesite?q=$( some computation from reading files )" is putting things
        tools:      tools the thing wants to use and how it wants to use them
            ( tool_name,  scope )
            ( tool_name,  scope )
            ( tool_name,  scope - for example, mkdir /tmp )
        dynamic:    if anything is going to be constructed programmatically, such as through generative ai
            ( what it does, how it's generated, via templates or whatever )
```

The "true" format is yaml however because urshies are designed to be ingested by various toolings they can be "emitted" as toml, yaml, or json. 

Here's the tasks. We need 

    1. an urshi manifest spec
    2. Tooling with tests that can read a file and make an urshi spec from a script url and a homepage
    3. A website where people can SSO log in (or not) and submit urls and homepages.
    4. If the script urls and homepages don't share the same domains and author paths, we flag them for manual review (for instance, a readme at github.com/microsoft/project-x and a script at github.com/randomuser-123/some-script.sh is not the same "source" since github is UGC and microsfot and randomuser-123 are not the same users)

Create separate directories for each of these tasks and use sub-agents to complete them

