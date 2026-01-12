const express = require('express');
const { getPromos } = require('../controllers/promoController');

const router = expressRouter();

router.get('/promos', getPromos);

module.exports = router;