<?php

/**
 * Set REMOTE_ADDR from HTTP_X_FORWARDED_FOR if set
 */
if (
    isset($_SERVER['HTTP_X_FORWARDED_FOR'])
    && $_SERVER['HTTP_X_FORWARDED_FOR'] != ''
) {
    $arr = explode(',',$_SERVER['HTTP_X_FORWARDED_FOR']);
    $_SERVER['REMOTE_ADDR'] = trim($arr[0]);
}

/**
 * Turn on HTTPS when ssl is terminated by various proxies
 */
if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO'])
    && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https'
) {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 80;
}

if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO_NEW'])
    && $_SERVER['HTTP_X_FORWARDED_PROTO_NEW'] == 'https'
) {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 80;
}

if (
    isset($_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'])
    && $_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] == 'https'
) {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 80;
}
