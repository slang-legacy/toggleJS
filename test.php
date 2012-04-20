<?php
	require 'dev/firephp/fb.php';
	ob_start();

	error_reporting( E_ALL );
	ini_set('display_errors', 1);

	require 'dev/lessphp/lessc.inc.php';
	function compileLess(){
	
		$cwd = getcwd();
		//mkdir($cwd . "/css");
	
		$handle = opendir('./');

		while (false !== ($entry = readdir($handle))) {
			if ($entry != "." && $entry != "..") {
				preg_match('/[a-z]*\./', $entry, $entry);//cut off file extension
				if($entry == 'less'){//checks if it has no file extension (like a directory)
					try {
						lessc::ccompile($entry[0] . 'less', 'css/' . $entry[0] . 'css');
					} catch (exception $ex) {
						echo $ex->getMessage();
					}
				}

			}
		}
		closedir($handle);
	}

	compileLess();

	exec('/home/sean/bin/coffee -c -o js/ ./', $output);
	var_dump($output);
?>