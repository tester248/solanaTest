import express from 'express';
import tokenRoutes from './routes/tokenRoutes';

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use('/api', tokenRoutes);

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});