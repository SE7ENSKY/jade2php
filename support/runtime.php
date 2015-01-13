<?php

error_reporting(E_ALL & ~E_NOTICE);

function attr($name, $value = true, $escaped = true) {
	if (!empty($value)) {
		echo " $name=\"$value\"";
	}
}

function attrs() {
	$args = func_get_args();
	$attrs = array();
	foreach ($args as $arg) {
		foreach ($arg as $key => $value) {
			if ($key == 'class') {
				if (!isset($attrs[$key])) $attrs[$key] = array();
				$attrs[$key] = array_merge($attrs[$key], is_array($value) ? $value : explode(' ', $value));
			} else {
				$attrs[$key] = $value;
			}
		}
	}
	foreach ($attrs as $key => $value) {
		if ($key == 'class') {
			attr_class($value);
		} else {
			attr($key, $value);
		}
	}
}

function attr_class() {
	$classes = array();
	$args = func_get_args();
	foreach ($args as $arg) {
		if (empty($arg) || is_array($arg) && count($arg) == 0) continue;
		$classes = array_merge($classes, is_array($arg) ? $arg : array($arg));
	}
	$classes = array_filter($classes);
	if (count($classes) > 0) attr('class', join(' ', $classes));
}

function add() {
	$result = '';
	$args = func_get_args();
	$concat = false;
	foreach ($args as $arg) {
		if ($concat || is_string($arg)) {
			$concat = true;
			$result .= $arg;
		} elseif (is_numeric($arg)) {
			if ($result === '') $result = 0;
			$result += $arg;
		}
	}
	return $result;
}

?>