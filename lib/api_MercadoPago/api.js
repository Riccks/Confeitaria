const express = require('express');
const MercadoPago = require('mercadopago');

const app = express();
app.use(express.json());

MercadoPago.configure({
  access_token: 'TEST-3712368975998688-120612-c59f6419acad345f9ae0d18c5f07e2d5-1981780315',
});

app.post('/create_preference', (req, res) => {
  const items = req.body.items;

  let preference = {
    items: items,
    payment_methods: {
      excluded_payment_methods: [
        { id: "bolbradesco" },
        { id: "pec" }
      ],
      installments: 3
    },
    auto_return: 'approved',
  };

  MercadoPago.preferences.create(preference)
    .then(function(response){
      res.json({
        id: response.body.id,
        init_point: response.body.init_point
      });
    }).catch(function(error){
      console.error(error);
      res.status(500).send('Error creating preference');
    });
});

app.listen(3000, () => {
  console.log('Server is running on port 3000');
});
