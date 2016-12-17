# Change Log

## [v0.8.1](https://github.com/swanandp/acts_as_list/tree/v0.8.1) (2016-09-06)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.8.0...v0.8.1)

**Closed issues:**

- Rubinius Intermittent testing error [\#218](https://github.com/swanandp/acts_as_list/issues/218)
- ActiveRecord dependency causes rake assets:compile to fail without access to a database [\#84](https://github.com/swanandp/acts_as_list/issues/84)

**Merged pull requests:**

- Refactor class\_eval with string into class\_eval with block [\#215](https://github.com/swanandp/acts_as_list/pull/215) ([rdvdijk](https://github.com/rdvdijk))

## [v0.8.0](https://github.com/swanandp/acts_as_list/tree/v0.8.0) (2016-08-23)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.7...v0.8.0)

**Closed issues:**

- Behavior with DB default seems unclear [\#219](https://github.com/swanandp/acts_as_list/issues/219)

**Merged pull requests:**

- No longer a need specify additional rbx gems [\#225](https://github.com/swanandp/acts_as_list/pull/225) ([brendon](https://github.com/brendon))
- Fix position when no serial positions [\#223](https://github.com/swanandp/acts_as_list/pull/223) ([jpalumickas](https://github.com/jpalumickas))
- Bug: Specifying a position with add\_new\_at: :top fails to insert at that position [\#220](https://github.com/swanandp/acts_as_list/pull/220) ([brendon](https://github.com/brendon))

## [v0.7.7](https://github.com/swanandp/acts_as_list/tree/v0.7.7) (2016-08-18)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.6...v0.7.7)

**Closed issues:**

- Issue after upgrading to 0.7.5: No connection pool with id primary found. [\#214](https://github.com/swanandp/acts_as_list/issues/214)
- Changing scope is inconsistent based on add\_new\_at [\#138](https://github.com/swanandp/acts_as_list/issues/138)
- Duplicate positions and lost items [\#76](https://github.com/swanandp/acts_as_list/issues/76)

**Merged pull requests:**

- Add quoted table names to some columns [\#221](https://github.com/swanandp/acts_as_list/pull/221) ([jpalumickas](https://github.com/jpalumickas))
- Appraisals cleanup [\#217](https://github.com/swanandp/acts_as_list/pull/217) ([brendon](https://github.com/brendon))
- Fix insert\_at\_position in race condition [\#195](https://github.com/swanandp/acts_as_list/pull/195) ([danielross](https://github.com/danielross))

## [v0.7.6](https://github.com/swanandp/acts_as_list/tree/v0.7.6) (2016-07-15)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.5...v0.7.6)

**Closed issues:**

- add\_new\_at nil with scope causes NoMethodError [\#211](https://github.com/swanandp/acts_as_list/issues/211)

**Merged pull requests:**

- Add class method acts\_as\_list\_top as reader for configured top\_of\_list [\#213](https://github.com/swanandp/acts_as_list/pull/213) ([krzysiek1507](https://github.com/krzysiek1507))
- Bugfix/add new at nil on scope change [\#212](https://github.com/swanandp/acts_as_list/pull/212) ([greatghoul](https://github.com/greatghoul))

## [v0.7.5](https://github.com/swanandp/acts_as_list/tree/v0.7.5) (2016-06-30)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.4...v0.7.5)

**Implemented enhancements:**

- Touch when reordering [\#173](https://github.com/swanandp/acts_as_list/pull/173) ([botandrose](https://github.com/botandrose))

**Closed issues:**

- Exception raised when calling destroy "NameError - instance variable @scope\_changed not defined:" [\#206](https://github.com/swanandp/acts_as_list/issues/206)
- Undefined instance variable @scope\_changed since 0.7.3 [\#199](https://github.com/swanandp/acts_as_list/issues/199)
- Reordering large lists is slow [\#198](https://github.com/swanandp/acts_as_list/issues/198)
- Reparenting child leaves gap in source list in rails 5 [\#194](https://github.com/swanandp/acts_as_list/issues/194)
- Support rails 5 ? [\#186](https://github.com/swanandp/acts_as_list/issues/186)
- I get a NoMethodError: undefined method `acts\_as\_list' when trying to include acts\_as\_list [\#176](https://github.com/swanandp/acts_as_list/issues/176)
- Phenomenon of mysterious value of the position is skipped by one [\#166](https://github.com/swanandp/acts_as_list/issues/166)
- Model.find being called twice with acts\_as\_list on destroy [\#161](https://github.com/swanandp/acts_as_list/issues/161)
- `scope\_changed?` problem with acts\_as\_paranoid [\#158](https://github.com/swanandp/acts_as_list/issues/158)
- Inconsistent behaviour between Symbol and Array scopes [\#155](https://github.com/swanandp/acts_as_list/issues/155)
- insert\_at doesn't seem to be working in ActiveRecord callback \(Rails 4.2\) [\#150](https://github.com/swanandp/acts_as_list/issues/150)
- Project Documentation link redirects to expired domain [\#149](https://github.com/swanandp/acts_as_list/issues/149)
- Problem when updating an position of array of AR objects. [\#137](https://github.com/swanandp/acts_as_list/issues/137)
- Unexpected behaviour when inserting consecutive items with default positions [\#124](https://github.com/swanandp/acts_as_list/issues/124)
- self.reload prone to error [\#122](https://github.com/swanandp/acts_as_list/issues/122)
- Rails 3.0.x in\_list causes the return of default\_scope [\#120](https://github.com/swanandp/acts_as_list/issues/120)
- Relationships with dependency:destroy cause ActiveRecord::RecordNotFound [\#118](https://github.com/swanandp/acts_as_list/issues/118)
- Using insert\_at with values with type String [\#117](https://github.com/swanandp/acts_as_list/issues/117)
- Batch setting of position [\#112](https://github.com/swanandp/acts_as_list/issues/112)
- position: 0 now makes model pushed to top? [\#110](https://github.com/swanandp/acts_as_list/issues/110)
- Create element in default position [\#103](https://github.com/swanandp/acts_as_list/issues/103)
- Enhancement: Expose scope object [\#97](https://github.com/swanandp/acts_as_list/issues/97)
- Shuffle list [\#96](https://github.com/swanandp/acts_as_list/issues/96)
- Creating an item with a nil scope should not add it to the list [\#92](https://github.com/swanandp/acts_as_list/issues/92)
- Performance Improvements  [\#88](https://github.com/swanandp/acts_as_list/issues/88)
- has\_many :through or has\_many\_and\_belongs\_to\_many support [\#86](https://github.com/swanandp/acts_as_list/issues/86)
- move\_higher/move\_lower vs move\_to\_top/move\_to\_bottom act differently when item is already at top or bottom [\#77](https://github.com/swanandp/acts_as_list/issues/77)
- Limiting the list size [\#61](https://github.com/swanandp/acts_as_list/issues/61)
- Adding multiple creates strange ordering [\#55](https://github.com/swanandp/acts_as_list/issues/55)
- Feature: sort [\#26](https://github.com/swanandp/acts_as_list/issues/26)

**Merged pull requests:**

- Fix position when no serial positions [\#208](https://github.com/swanandp/acts_as_list/pull/208) ([PoslinskiNet](https://github.com/PoslinskiNet))
- Removed duplicated assignment [\#207](https://github.com/swanandp/acts_as_list/pull/207) ([shunwen](https://github.com/shunwen))
- Quote all identifiers [\#205](https://github.com/swanandp/acts_as_list/pull/205) ([fabn](https://github.com/fabn))
- Start testing Rails 5 [\#203](https://github.com/swanandp/acts_as_list/pull/203) ([brendon](https://github.com/brendon))
- Lock! the record before destroying [\#201](https://github.com/swanandp/acts_as_list/pull/201) ([brendon](https://github.com/brendon))
- Fix ambiguous column error when joining some relations [\#180](https://github.com/swanandp/acts_as_list/pull/180) ([natw](https://github.com/natw))

## [v0.7.4](https://github.com/swanandp/acts_as_list/tree/v0.7.4) (2016-04-15)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.3...v0.7.4)

**Closed issues:**

- Releasing a new gem version [\#196](https://github.com/swanandp/acts_as_list/issues/196)

**Merged pull requests:**

- Fix scope changed [\#200](https://github.com/swanandp/acts_as_list/pull/200) ([brendon](https://github.com/brendon))

## [v0.7.3](https://github.com/swanandp/acts_as_list/tree/v0.7.3) (2016-04-14)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/v0.7.2...v0.7.3)

## [v0.7.2](https://github.com/swanandp/acts_as_list/tree/v0.7.2) (2016-04-01)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.7.2...v0.7.2)

**Closed issues:**

- DEPRECATION WARNING: Passing string to define callback on Rails 5 beta 3 [\#191](https://github.com/swanandp/acts_as_list/issues/191)
- Why is `add\_to\_list\_bottom` private? [\#187](https://github.com/swanandp/acts_as_list/issues/187)
- Ordering of children when there are two possible parent models. [\#172](https://github.com/swanandp/acts_as_list/issues/172)
- Fix the jruby and rbx builds [\#169](https://github.com/swanandp/acts_as_list/issues/169)
- Unable to run tests [\#162](https://github.com/swanandp/acts_as_list/issues/162)
- shuffle\_positions\_on\_intermediate\_items is creating problems [\#134](https://github.com/swanandp/acts_as_list/issues/134)
- introduce Changelog file to quickly track changes [\#68](https://github.com/swanandp/acts_as_list/issues/68)
- Mongoid support? [\#52](https://github.com/swanandp/acts_as_list/issues/52)

**Merged pull requests:**

- Add filename/line number to class\_eval call [\#193](https://github.com/swanandp/acts_as_list/pull/193) ([hfwang](https://github.com/hfwang))
- Use a symbol as a string to define callback [\#192](https://github.com/swanandp/acts_as_list/pull/192) ([brendon](https://github.com/brendon))
- Pin changelog generator to a working version [\#190](https://github.com/swanandp/acts_as_list/pull/190) ([fabn](https://github.com/fabn))
- Fix bug, position is recomputed when object saved [\#188](https://github.com/swanandp/acts_as_list/pull/188) ([chrisortman](https://github.com/chrisortman))
- Update bundler before running tests, fixes test run on travis [\#179](https://github.com/swanandp/acts_as_list/pull/179) ([fabn](https://github.com/fabn))
- Changelog generator, closes \#68 [\#177](https://github.com/swanandp/acts_as_list/pull/177) ([fabn](https://github.com/fabn))
- Updating README example [\#175](https://github.com/swanandp/acts_as_list/pull/175) ([ryanbillings](https://github.com/ryanbillings))
- Adds description about various options available with the acts\_as\_list method [\#168](https://github.com/swanandp/acts_as_list/pull/168) ([udit7590](https://github.com/udit7590))
- Small changes to DRY up list.rb [\#163](https://github.com/swanandp/acts_as_list/pull/163) ([Albin-Willman](https://github.com/Albin-Willman))
- Only swap changed attributes which are persistable, i.e. are DB columns. [\#152](https://github.com/swanandp/acts_as_list/pull/152) ([ludwigschubert](https://github.com/ludwigschubert))

## [0.7.2](https://github.com/swanandp/acts_as_list/tree/0.7.2) (2015-05-06)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.7.1...0.7.2)

## [0.7.1](https://github.com/swanandp/acts_as_list/tree/0.7.1) (2015-05-06)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.7.0...0.7.1)

**Merged pull requests:**

- Update README.md [\#159](https://github.com/swanandp/acts_as_list/pull/159) ([tibastral](https://github.com/tibastral))

## [0.7.0](https://github.com/swanandp/acts_as_list/tree/0.7.0) (2015-05-01)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.6.0...0.7.0)

**Closed issues:**

- Problem with reordering scoped list items [\#154](https://github.com/swanandp/acts_as_list/issues/154)
- Can no longer load acts\_as\_list in isolation if Rails is installed [\#145](https://github.com/swanandp/acts_as_list/issues/145)

**Merged pull requests:**

- Fix regression with using acts\_as\_list on base classes [\#147](https://github.com/swanandp/acts_as_list/pull/147) ([botandrose](https://github.com/botandrose))
- Don't require rails when loading [\#146](https://github.com/swanandp/acts_as_list/pull/146) ([botandrose](https://github.com/botandrose))

## [0.6.0](https://github.com/swanandp/acts_as_list/tree/0.6.0) (2014-12-24)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.5.0...0.6.0)

**Closed issues:**

- Deprecation Warning: sanitize\_sql\_hash\_for\_conditions is deprecated and will be removed in Rails 5.0 [\#143](https://github.com/swanandp/acts_as_list/issues/143)
- Release a new gem version [\#136](https://github.com/swanandp/acts_as_list/issues/136)

**Merged pull requests:**

- Fix sanitize\_sql\_hash\_for\_conditions deprecation warning in Rails 4.2 [\#140](https://github.com/swanandp/acts_as_list/pull/140) ([eagletmt](https://github.com/eagletmt))
- Simpler method to find the subclass name [\#139](https://github.com/swanandp/acts_as_list/pull/139) ([brendon](https://github.com/brendon))
- Rails4 enum column support [\#130](https://github.com/swanandp/acts_as_list/pull/130) ([arunagw](https://github.com/arunagw))
- use eval for determing the self.class.name useful when this is used in an abstract class [\#123](https://github.com/swanandp/acts_as_list/pull/123) ([flarik](https://github.com/flarik))

## [0.5.0](https://github.com/swanandp/acts_as_list/tree/0.5.0) (2014-10-31)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.4.0...0.5.0)

**Closed issues:**

- I want to have my existing records works like list [\#133](https://github.com/swanandp/acts_as_list/issues/133)
- Add Support For Multiple Indexes [\#127](https://github.com/swanandp/acts_as_list/issues/127)
- changing parent\_id does not update item positions [\#126](https://github.com/swanandp/acts_as_list/issues/126)
- How to exclude objects to be positioned? [\#125](https://github.com/swanandp/acts_as_list/issues/125)
- Scope for Polymorphic association + ManyToMany [\#106](https://github.com/swanandp/acts_as_list/issues/106)
- Bug when use \#insert\_at on an invalid ActiveRecord object [\#99](https://github.com/swanandp/acts_as_list/issues/99)
- has\_many :through with acts as list [\#95](https://github.com/swanandp/acts_as_list/issues/95)
- Update position when scope changes [\#19](https://github.com/swanandp/acts_as_list/issues/19)

**Merged pull requests:**

- Cast column default value to int before comparing with position column [\#129](https://github.com/swanandp/acts_as_list/pull/129) ([wioux](https://github.com/wioux))
- Fix travis builds for rbx [\#128](https://github.com/swanandp/acts_as_list/pull/128) ([meineerde](https://github.com/meineerde))
- Use unscoped blocks instead of chaining [\#121](https://github.com/swanandp/acts_as_list/pull/121) ([brendon](https://github.com/brendon))
- Make acts\_as\_list more compatible with BINARY column [\#116](https://github.com/swanandp/acts_as_list/pull/116) ([sikachu](https://github.com/sikachu))
- Added help notes on non-association scopes [\#115](https://github.com/swanandp/acts_as_list/pull/115) ([VorontsovIE](https://github.com/VorontsovIE))
- Let AR::Base properly lazy-loaded if Railtie is available [\#114](https://github.com/swanandp/acts_as_list/pull/114) ([amatsuda](https://github.com/amatsuda))

## [0.4.0](https://github.com/swanandp/acts_as_list/tree/0.4.0) (2014-02-22)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.3.0...0.4.0)

**Closed issues:**

- insert\_at creates gaps [\#108](https://github.com/swanandp/acts_as_list/issues/108)
- move\_lower and move\_higher not working returning nil [\#57](https://github.com/swanandp/acts_as_list/issues/57)
- Mass-assignment issue with 0.1.8 [\#50](https://github.com/swanandp/acts_as_list/issues/50)
- validates error [\#49](https://github.com/swanandp/acts_as_list/issues/49)
- Ability to move multiple at once [\#40](https://github.com/swanandp/acts_as_list/issues/40)
- Duplicates created when using accepts\_nested\_attributes\_for [\#29](https://github.com/swanandp/acts_as_list/issues/29)

**Merged pull requests:**

- Update README [\#107](https://github.com/swanandp/acts_as_list/pull/107) ([Senjai](https://github.com/Senjai))
- Add license info: license file and gemspec [\#105](https://github.com/swanandp/acts_as_list/pull/105) ([chulkilee](https://github.com/chulkilee))
- Fix top position when position is lower than top position [\#104](https://github.com/swanandp/acts_as_list/pull/104) ([csaura](https://github.com/csaura))
- Get specs running under Rails 4.1.0.beta1 [\#101](https://github.com/swanandp/acts_as_list/pull/101) ([petergoldstein](https://github.com/petergoldstein))
- Add support for JRuby and Rubinius specs [\#100](https://github.com/swanandp/acts_as_list/pull/100) ([petergoldstein](https://github.com/petergoldstein))
- Use the correct syntax for conditions in Rails 4 on the readme. [\#94](https://github.com/swanandp/acts_as_list/pull/94) ([gotjosh](https://github.com/gotjosh))
- Adds `required\_ruby\_version` to gemspec [\#90](https://github.com/swanandp/acts_as_list/pull/90) ([tvdeyen](https://github.com/tvdeyen))

## [0.3.0](https://github.com/swanandp/acts_as_list/tree/0.3.0) (2013-08-02)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.2.0...0.3.0)

**Closed issues:**

- act\_as\_list didn't install with bundle install [\#83](https://github.com/swanandp/acts_as_list/issues/83)
- Cannot update to version 0.1.7 [\#48](https://github.com/swanandp/acts_as_list/issues/48)
- when position is null all new items get inserted in position 1 [\#41](https://github.com/swanandp/acts_as_list/issues/41)

**Merged pull requests:**

- Test against activerecord v3 and v4 [\#82](https://github.com/swanandp/acts_as_list/pull/82) ([sanemat](https://github.com/sanemat))
- Fix check\_scope to work on lists with array scopes [\#81](https://github.com/swanandp/acts_as_list/pull/81) ([conzett](https://github.com/conzett))
- Rails4 compatibility [\#80](https://github.com/swanandp/acts_as_list/pull/80) ([philippfranke](https://github.com/philippfranke))
- Add tests for moving within scope and add method: move\_within\_scope [\#79](https://github.com/swanandp/acts_as_list/pull/79) ([philippfranke](https://github.com/philippfranke))
- Option to not automatically add items to the list [\#72](https://github.com/swanandp/acts_as_list/pull/72) ([forrest](https://github.com/forrest))

## [0.2.0](https://github.com/swanandp/acts_as_list/tree/0.2.0) (2013-02-28)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.9...0.2.0)

**Merged pull requests:**

- Fix update\_all deprecation warnings in Rails 4.0.0.beta1 [\#73](https://github.com/swanandp/acts_as_list/pull/73) ([soffes](https://github.com/soffes))
- Add quotes to Id in SQL requests [\#69](https://github.com/swanandp/acts_as_list/pull/69) ([noefroidevaux](https://github.com/noefroidevaux))
- Update position when scope changes [\#67](https://github.com/swanandp/acts_as_list/pull/67) ([philippfranke](https://github.com/philippfranke))
- add and categorize public instance methods in readme; add misc notes to ... [\#66](https://github.com/swanandp/acts_as_list/pull/66) ([barelyknown](https://github.com/barelyknown))
- Updates \#bottom\_item .find syntax to \>= Rails 3 compatible syntax. [\#65](https://github.com/swanandp/acts_as_list/pull/65) ([tvdeyen](https://github.com/tvdeyen))
- add GitHub Flavored Markdown to README [\#63](https://github.com/swanandp/acts_as_list/pull/63) ([phlipper](https://github.com/phlipper))

## [0.1.9](https://github.com/swanandp/acts_as_list/tree/0.1.9) (2012-12-04)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.8...0.1.9)

**Closed issues:**

- Mysql2 error [\#54](https://github.com/swanandp/acts_as_list/issues/54)
- Use alternative column name? [\#53](https://github.com/swanandp/acts_as_list/issues/53)

**Merged pull requests:**

- attr-accessible can be damaging, is not always necessary. [\#60](https://github.com/swanandp/acts_as_list/pull/60) ([graemeworthy](https://github.com/graemeworthy))
- More reliable lower/higher item detection [\#59](https://github.com/swanandp/acts_as_list/pull/59) ([miks](https://github.com/miks))
- Instructions for using an array with scope [\#58](https://github.com/swanandp/acts_as_list/pull/58) ([zukowski](https://github.com/zukowski))
- Attr accessible patch, should solve \#50 [\#51](https://github.com/swanandp/acts_as_list/pull/51) ([fabn](https://github.com/fabn))
- support accepts\_nested\_attributes\_for multi-destroy [\#46](https://github.com/swanandp/acts_as_list/pull/46) ([saberma](https://github.com/saberma))

## [0.1.8](https://github.com/swanandp/acts_as_list/tree/0.1.8) (2012-08-09)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.7...0.1.8)

## [0.1.7](https://github.com/swanandp/acts_as_list/tree/0.1.7) (2012-08-09)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.6...0.1.7)

**Closed issues:**

- Remove use of update\_attribute [\#44](https://github.com/swanandp/acts_as_list/issues/44)
- Order is reversed when adding multiple rows at once [\#34](https://github.com/swanandp/acts_as_list/issues/34)

**Merged pull requests:**

- Fixed issue with update\_positions that wasn't taking 'scope\_condition' into account [\#47](https://github.com/swanandp/acts_as_list/pull/47) ([bastien](https://github.com/bastien))
- Replaced usage of update\_attribute with update\_attribute!  [\#45](https://github.com/swanandp/acts_as_list/pull/45) ([kevmoo](https://github.com/kevmoo))
- use self.class.primary\_key instead of id in shuffle\_positions\_on\_intermediate\_items [\#42](https://github.com/swanandp/acts_as_list/pull/42) ([servercrunch](https://github.com/servercrunch))
- initialize gem [\#39](https://github.com/swanandp/acts_as_list/pull/39) ([megatux](https://github.com/megatux))
- Added ability to set item positions directly \(e.g. In a form\) [\#38](https://github.com/swanandp/acts_as_list/pull/38) ([dubroe](https://github.com/dubroe))
- Prevent SQL error when position\_column is not unique [\#37](https://github.com/swanandp/acts_as_list/pull/37) ([hinrik](https://github.com/hinrik))
- Add installation instructions to README.md [\#35](https://github.com/swanandp/acts_as_list/pull/35) ([mark-rushakoff](https://github.com/mark-rushakoff))

## [0.1.6](https://github.com/swanandp/acts_as_list/tree/0.1.6) (2012-04-19)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.5...0.1.6)

**Closed issues:**

- eval mistakenly resolved the module path [\#32](https://github.com/swanandp/acts_as_list/issues/32)
- Duplicated positions when creating parent and children from scratch in 0.1.5 [\#31](https://github.com/swanandp/acts_as_list/issues/31)
- add info about v0.1.5 require Rails 3 [\#28](https://github.com/swanandp/acts_as_list/issues/28)
- position not updated with move\_higher or move\_lover [\#23](https://github.com/swanandp/acts_as_list/issues/23)

**Merged pull requests:**

- update ActiveRecord class eval to support ActiveSupport on\_load [\#33](https://github.com/swanandp/acts_as_list/pull/33) ([mergulhao](https://github.com/mergulhao))
- Add :add\_new\_at option [\#30](https://github.com/swanandp/acts_as_list/pull/30) ([mjbellantoni](https://github.com/mjbellantoni))

## [0.1.5](https://github.com/swanandp/acts_as_list/tree/0.1.5) (2012-02-24)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.4...0.1.5)

**Closed issues:**

- increment\_positions\_on\_lower\_items called twice on insert\_at with new item [\#21](https://github.com/swanandp/acts_as_list/issues/21)
- Change bundler dependency from ~\>1.0.0 to ~\>1.0 [\#20](https://github.com/swanandp/acts_as_list/issues/20)
- decrement\_positions\_on\_lower\_items method [\#17](https://github.com/swanandp/acts_as_list/issues/17)
- New gem release [\#16](https://github.com/swanandp/acts_as_list/issues/16)
- acts\_as\_list :scope =\> "doesnt\_seem\_to\_work" [\#12](https://github.com/swanandp/acts_as_list/issues/12)
- don't work perfectly with default\_scope [\#11](https://github.com/swanandp/acts_as_list/issues/11)
- MySQL: Position column MUST NOT have default [\#10](https://github.com/swanandp/acts_as_list/issues/10)
- insert\_at fails on postgresql w/ non-null constraint on postion\_column  [\#8](https://github.com/swanandp/acts_as_list/issues/8)

**Merged pull requests:**

- Efficiency improvement for insert\_at when repositioning an existing item [\#27](https://github.com/swanandp/acts_as_list/pull/27) ([bradediger](https://github.com/bradediger))
- Use before validate instead of before create [\#25](https://github.com/swanandp/acts_as_list/pull/25) ([webervin](https://github.com/webervin))
- Massive test refactorings. [\#24](https://github.com/swanandp/acts_as_list/pull/24) ([splattael](https://github.com/splattael))
- Silent migrations to reduce test noise. [\#22](https://github.com/swanandp/acts_as_list/pull/22) ([splattael](https://github.com/splattael))
- Should decrement lower items after the item has been destroyed to avoid unique key conflicts. [\#18](https://github.com/swanandp/acts_as_list/pull/18) ([aepstein](https://github.com/aepstein))
- Fix spelling and grammer [\#15](https://github.com/swanandp/acts_as_list/pull/15) ([tmiller](https://github.com/tmiller))
- store\_at\_0 should yank item from the list then decrement items to avoid r [\#14](https://github.com/swanandp/acts_as_list/pull/14) ([aepstein](https://github.com/aepstein))
- Support default\_scope ordering by calling .unscoped [\#13](https://github.com/swanandp/acts_as_list/pull/13) ([tanordheim](https://github.com/tanordheim))

## [0.1.4](https://github.com/swanandp/acts_as_list/tree/0.1.4) (2011-07-27)
[Full Changelog](https://github.com/swanandp/acts_as_list/compare/0.1.3...0.1.4)

**Merged pull requests:**

- Fix sqlite3 dependency [\#7](https://github.com/swanandp/acts_as_list/pull/7) ([joneslee85](https://github.com/joneslee85))

## [0.1.3](https://github.com/swanandp/acts_as_list/tree/0.1.3) (2011-06-10)
**Closed issues:**

- Graph like behaviour [\#5](https://github.com/swanandp/acts_as_list/issues/5)
- Updated Gem? [\#4](https://github.com/swanandp/acts_as_list/issues/4)

**Merged pull requests:**

- Converted into a gem... plus some slight refactors [\#6](https://github.com/swanandp/acts_as_list/pull/6) ([chaffeqa](https://github.com/chaffeqa))
- Fixed test issue for test\_injection: expected SQL was reversed. [\#3](https://github.com/swanandp/acts_as_list/pull/3) ([afriqs](https://github.com/afriqs))
- Added an option to set the top of the position [\#2](https://github.com/swanandp/acts_as_list/pull/2) ([danielcooper](https://github.com/danielcooper))
- minor change to acts\_as\_list's callbacks [\#1](https://github.com/swanandp/acts_as_list/pull/1) ([tiegz](https://github.com/tiegz))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*