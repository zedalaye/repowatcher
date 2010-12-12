Repository Walker
=================

I use this piece of code to manage the bunch of OpenSource softwares I use to follow.

I have a /home/me/Sources directory containing several dozens of repositories of any 
kinds. Today I need to clean my hard drive up a bit so I wrote this piece of 
code that discovers all the repositories (Subversion, Git, Mercurial, GClient (Android), 
DepotTools (Chrome)) living in that Sources directory and writes an XML file containing
the kind of all discovered repositories with their root URL and the local root directory
where they are stored.

Prerequisites
-------------

You will need the builder gem try -- `gem install builder`. It helps me to create 
valid XML files.

You will also need the svn, git and hg commands to be available in your path as
they will be called by this script.

How to use ?
------------

Just clone this repository, give the depot.rb the executable rights and... run it.

You will get an XML file looking like :

    <?xml version="1.0" encoding="UTF-8"?>
    <projects root="/home/pierre/Source">
      <project scm="Subversion">
        <url>http://firebird.svn.sourceforge.net/svnroot/firebird/firebird/trunk</url>
        <local>Firebird/fb</local>
      </project>
      <project scm="Subversion">
        <url>http://firebird.svn.sourceforge.net/svnroot/firebird/firebird/branches/B2_5_Release</url>
        <local>Firebird/fb25</local>
      </project>
      <project scm="Subversion">
        <url>http://flamerobin.svn.sourceforge.net/svnroot/flamerobin/trunk/flamerobin</url>
        <local>Firebird/flamerobin</local>
      </project>
    </projects>

Options
-------

Now, depots script supports command line options. Try -h to see supported options.

Use `-d PATH` to tell the script where to start search for repositories. `-o FILE` names 
the output file, `-v` means it has to be verbose and `-s key` which key to use to sort
the repositories before dumping them to the output file.

Default search path is '.', the current directory, the default filename is 'projects.xml',
the script is not verbose by default and sorts the repositories by local directory name.

Available sort keys : *base* [default] is the local directory name, *name* is the kind of repository
and *url* is the main repository url.

Plans
-----

I plan to add commands to update or checkout fresh version of one or all the
repositories registered in the projects.xml file.
