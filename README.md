SUMMARY
-------

**Scrum2B** is a plugin of Redmine (www.redmine.org), support Scrum Board and other features allow teams could use Scrum to develop Agile project.
Scrum2B is developed by Scrum2B Team.

***Contacts:***
- Email: *scrum2b@ithanoi.com*
- Website: *www.scrum2b.com*
- Facebook: *www.facebook.com/ScrumToBe*


**The first version (1.0) is quite simple, includes 3 main features:**

1. The ScrumBoard: based on another Redmine plugin with a board, but we completed more features, allow teams could treat like a REAL BOARD.
Users could drad and drop a task to sort/organizate the Sprint.
2. The ListBoard: list all issues based on the sort from ScrumBoard and make it more simple than Issue Tracking in Redmine.
3. The interface of screens based on Twitter Bootstrap, with better look and feeling.
(You should get the theme: https://github.com/scrum2b/redmine-scrum2b-theme to install in Redmine)

**You could see the demo version at:**
- *http://scrum2b.com/projects/scrum2b-demo*
- *http://scrum2b.com/scrum2b/board?project_id=scrum2b-demo*

(Please login with username/password: **demo/demo123** to get more detail how Scrum2B works)

*We are focus to make easier and more simple to practice Scrum in Project management. 
So if you find any new ideas to improve the tools, please do not hesitage to send message to me at scrum2b@ithanoi.com, 
Or create a Pull request (https://github.com/scrum2b/scrum2b/pulls) to us.*


LICENSE
-------

Scrum2B is open source and released under the terms of the GNU General Public License v2 (GPL)  (http://www.gnu.org/licenses/old-licenses/gpl-2.0.html)


INSTALLATION
------------

The tool could run based on Redmine 2.3.x, 2.2.x, 2.1.x, 2.0.x.

Go to the Redmine plugin folder. Clone the plugin from GitHub:
    
    $ git clone git@github.com:scrum2b/scrum2b.git
    $ 

Go back to the Redmine folder, update your bundle and migrate the database:

    $ bundle install
    $ rake redmine:plugins:migrate

Restart Redmine

Before make the plugin be available in projects, please login to Admin account.
Go to the Configuration page of the plugin to map the Status of issues to New/In progress/Complete/Closed:

    http://localhost:3000/settings/plugin/scrum2b 



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

If you have any comment/sugguession, please send message to us via Git Issues.

Thanks and best regards,
Scrum2B Team


