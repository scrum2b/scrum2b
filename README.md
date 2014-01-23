SUMMARY
-------

**Scrum2B tool** (www.scrum2b.com) is a Project Management application, developed by ScrumTobe Team (www.scrumtobe.com), is an Opensource - plugin of Redmine (www.redmine.org) and free to use in Scrum/Agile projects for Software development.
The newest version (2.0) is completed with more features:

1. The ScrumBoard: based on another Redmine plugin with a board, but we completed more features, allow teams could treat like a REAL BOARD. Users could drad and drop a task to sort/organizate the Sprint.
2. The Backlog Sprint: list all issues based on the sort from ScrumBoard, move issues to another sprints. The screen is designed mostly focus on managers and make it more simple than Issue Tracking in Redmine.
3. Users could show and edit detail information of issues, like Attach files, comments.
4. The plugin could run with many Redmine themes.

**You could see the demo version at:**
- *http://scrum2b.com/projects/scrum2b-demo*
- *http://scrum2b.com/scrum2b/board?project_id=scrum2b-demo*

(Please login with username/password: **demo/demo123** to get more detail how Scrum2B works)

*We are focus to make easier and more simple to practice Scrum in Project management. 
So if you find any new ideas to improve the tools, please do not hesitate to send message to me at scrum2b@ithanoi.com, 
Or create a Pull request (https://github.com/scrum2b/scrum2b/pulls) to us.*

***Contacts:***
- Email: *scrum2b@ithanoi.com*
- Demo tool: *www.scrum2b.com*
- Website: *www.scrumtobe.com*
- Facebook: *www.facebook.com/ScrumToBe* (Please "like" our profile if you have time :) )


LICENSE
-------

Scrum2B is open source and released under the terms of the GNU General Public License v2 (GPL)  (http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)


INSTALLATION
------------

The tool could run based on Redmine 2.4.x, 2.3.x, 2.2.x, 2.1.x, 2.0.x.
Please see more detail at wiki: https://github.com/scrum2b/scrum2b/wiki/Installation-Guide


FOR DEVELOPERS
--------------

Change to use "develop" branch for developers:

    $ git checkout -b develop origin/develop

Commit codes
  
    $ git fetch --all
    $ git merge origin/develop
    $ git commit -m "Message Content in here"
    $ git push -u origin develop


FOR FURTURE FEATURES
--------------------

We want to implement new features in short term:

1. Burndown chart based on Estimate Time and Spent Time.
2. The check list for each issues.
3. Plan sprints


If you have any comment/sugguession, please send message to us via Git Issues.



UNINSTALLATION
--------------


1. Go to the Redmine folder, run rake command to undo migrate the database:
  
    $ rake redmine:plugins:migrate NAME=scrum2b VERSION=0 RAILS_ENV=production 


    *(Parameter "VERSION=0" is very important, it set to revert migrations in the plugin.)*
    
2. Remove the plugin from the plugins folder: #{RAILS_ROOT}/plugins/scrum2b

3. Restart Redmine

