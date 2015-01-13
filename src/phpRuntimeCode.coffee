fs = require 'fs'
phpRuntimeCode = fs.readFileSync "#{__dirname}/../support/runtime.php", 'utf-8'
phpRuntimeCode = phpRuntimeCode.replace(///\n\s*///g, '').replace("<?php", "<?php ")

module.exports = phpRuntimeCode