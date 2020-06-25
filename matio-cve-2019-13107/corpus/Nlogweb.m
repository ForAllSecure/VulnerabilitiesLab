%
% logweb.m - this MATLAB file solves the 
% discrete logistic equation x(i+1)=r*x(i)*(1-x(i))
% and illustrates cobwebbing analysis
r=3.8;       % growth rate
x0=0.2;      %initial population x0
n=80;          %end of time interval
x=zeros(n+1,1);
t=zeros(n+1,1);
x(1)=x0;
tt(1)=0;
for i=1:n
t(i)=i-1;
x(i+1)=r*x(i)*(1-x(i));
end
t(n+1)=n;
nn=100;
del=1./nn;
xstart=0;
yy=zeros(nn+1,1);
lin=zeros(nn+1,1);
xx=zeros(nn+1,1);
for i=1:nn+1
xx(i)=xstart+(i-1)*del;
lin(i)=xx(i);
yy(i)=r*xx(i)*(1-xx(i));
end
plot(xx,lin,xx,yy),pause
xc=zeros(24,1);
yc=zeros(24,1);
xc(1)=x0;
yc(1)=0;
xc(2)=x0;
yc(2)=r*x0*(1-x0);
yc(3)=yc(2);
xc(3)=yc(2);
plot(xx,lin,xx,yy,xc,yc),pause
for j=3:20;
jj=2*j-4;
xc(jj)=xc(jj-1);
yc(jj)=r*xc(jj)*(1-xc(jj));
xc(jj+1)=yc(jj);
yc(jj+1)=yc(jj);
plot(xx,lin,xx,yy,xc,yc),pause
end
plot(t,x,t,x,'o');
