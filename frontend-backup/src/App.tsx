
import { Provider } from '@shopify/app-bridge-react';
import { TitleBar } from '@shopify/app-bridge-react';
import { useEffect, useState } from 'react';
import axios from 'axios';

const config = {
  apiKey: import.meta.env.VITE_SHOPIFY_API_KEY,
  host: new URLSearchParams(window.location.search).get('host') || btoa('localhost:3000'),
};

function App() {
  const [products, setProducts] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:3000/products').then((response) => {
      setProducts(response.data);
    });
  }, []);

  return (
    <Provider config={config}>
      <TitleBar title="Shopify App" />
      <div className="p-4">
        <h1 className="text-2xl font-bold">Products</h1>
        <ul>
          {products.map((product: any) => (
            <li key={product.id}>{product.title} - ${product.price}</li>
          ))}
        </ul>
      </div>
    </Provider>
  );
}

export default App;